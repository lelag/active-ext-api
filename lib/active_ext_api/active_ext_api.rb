# ActiveExtAPI is a module that inject methods to an ActiveRecord model 
# that implements an API that can be used to communicate with an ExtJS Store's CRUD API.
# It will add the following 4 methods :
#   - ext_read : used to load a store
#   - ext_create : used to create records
#   - ext_update : used to update records
#   - ext_delete : used to delete records
# @author Le Lag
module ActiveExtAPI 
  DEFAULT_METHODS = { 'ext_read' => 1, 'ext_create' => 1, 'ext_update' => 1, 'ext_destroy' => 1 }
  EXT_SUPPORTED_OPTIONS = {
    :ext_read => [:limit, :offset, :start, :sort, :dir, :conditions, :order, :group, :having, :joins, :include, :select, :from, :readonly, :lock],
    :ext_create => [:data],
    :ext_update => [:data, :on_edit],
    :ext_destroy => [:data] }

  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    # Register the Ext API methods as available to the Direct RPC calls.
    #
    # @param [Hash] direct methods direct_methods that can be made accessible through the ActiveDirect api
    # @example make a foobar method taking 1 argument available to the Direct RPC API.
    #  acts_as_direct_ext_api {:foobar => 1}
    # @author Adapted from code from Stone Gao's ActiveDirect library github.com/stonegao/active-direct
    def acts_as_direct_ext_api(direct_methods = {})
        raise "ActiveDirect was not found " if self.methods.include? "acts_as_direct" == false 
        ActiveDirect::Config.method_config[self.to_s].clear
        direct_methods.stringify_keys!.merge!(DEFAULT_METHODS).each do |mtd, mcfg|
          if mcfg.is_a?(Hash)
            ActiveDirect::Config.method_config[self.to_s] << {'name' => mtd}.merge!(mcfg)
          else
            ActiveDirect::Config.method_config[self.to_s] << { 'name' => mtd, 'len' => mcfg }
          end
        end
    end

    # Filter the unsupported options that can be used in certain api method but not others
    #
    # @param [Symbol] sym the name of the method
    # @param [Hash] options an options hash
    # @return [Hash] return options without any options not defined in EXT_SUPPORTED_OPTIONS
    def filter_unsupported_options(sym, options = {}) 
      options.delete_if do |key, value|
        !EXT_SUPPORTED_OPTIONS[sym].include? key
      end
    end

    # Get the total count for a find query ignoring limits
    # @param [Hash] opts the options for a ActiveRecord::Base.find call
    # @return [Integer] the total number of rows for the query ignoring limit and offset
    def get_total_count(opts = {}) 
        opts[:limit] = nil
        opts[:offset] = nil
        opts[:select] = "count(*)"
        sql_count = construct_finder_sql(opts)
        count_by_sql(sql_count)
    end


    # Recursively call methods in associated ActiveRecord (or other) object
    #
    # @example calling book.author.country.name= "France" 
    #   call_func(book, ["author", "country", "name"], "France")
    #
    # @example calling book.author.country.save
    #    call_func(book, ["author", "country", "save"])
    #
    # @example calling book.author.books.each {|b| #-> save the title, the year and the country property }
    #    call_func(book, ["author", "books", ["title", "year", "country"]])
    #
    # @param [Object] ar The base object (here an ActiveRecord::Base instance) on which to start the call chain
    # @param [Array]  m An array containing the chain of method to call
    #   The last item of m can be an array with several method or attributes names
    #   In this case the return value will be a hash.
    # @param [optional Object]  v An optional value that will be assigned to the last item in the chain.  
    # @return The return value of the last method call in the chain
    # @private
    def call_func(ar, m, v = nil)
      m = [m] if !m.kind_of? Array
      mm = m[1, m.length - 1] 
      if mm == [] #last element
        if !m[0].kind_of? Array
          if v != nil
            ms = (m[0]+"=").to_sym
            ar.send ms, v 
          else
            ms = m[0].to_sym
            ar.send ms 
          end
        else
          narh = {}
          m[0].each do |ma| 
            if v != nil
              ms = (ma+"=").to_sym
              narh[ma] = ar.send ms, v 
            else
              ms = ma.to_sym
              narh[ma] = ar.send ms 
            end
          end
          narh
        end
      else
        ms = m[0].to_sym
        nar = ar.send ms
        if nar.kind_of? Array
          nara = []
          nar.each do |nari|
            nara.push call_func nari, mm, v 
          end
          nara
        else
          call_func nar, mm, v
        end
      end
    end

    # Transform a request to sort on a linked model into the table names
    #
    # @example 
    #   filter_sort_tables "artist.name" #=> "artists.name"
    # @example
    #   filter_sort_tables "artist.country.name" #=> "countries.name"
    # @param [String] v a sort options provided by Ext
    # @return the name of the attributes prefixed with a table name
    # @private
    def filter_sort_tables(v)
      a = v.split(".")
      if a.length == 1
        return a[0]
      end
      a[-2]= a[-2].pluralize
      a[-2,2].join(".")
    end

    # Transform Ext provided :sort / :dir options into rail's :order options
    #
    # @example
    #   filter_sort({:sort => "name", :dir=> "ASC"}) #=> {:order => "name ASC"}
    # @example
    #   filter_sort({:sort => [{:sort=>"name", :dir=>"ASC"}, {:sort=>"country", :dir=>"DESC"}]) #=> {:order => "name ASC, country DESC"}
    # @param [Hash] the options used to find records
    # @option opts [String] :sort the attributes that must be used to sort
    # @option opts [String] :dir the direction of the sort
    # @return [Hash] the provided options with :sort/:dir replaced by :order
    # @private
    def filter_sort(opts= {})
      if opts[:sort] != nil
        if(opts[:sort].kind_of? Array)
          s = []
          opts[:sort].each do |sort|
            sort_name = sort[:sort].split(".")

            s.push "#{filter_sort_tables sort[:sort]} #{sort[:dir]}"
          end
          opts.delete :sort
          opts[:order] = s.join(",")
        else
          sort= opts.delete :sort
          dir = opts.delete :dir || "ASC"
          opts[:order] = "#{filter_sort_tables sort} #{dir}"
        end
      end
      opts 
    end
    
    # Return a list of records that can be used to load an ExtJS Store
    #
    # @param [Hash] opts the options provided by ExtJS to request records
    # @option opts [String] :sort the attributes that must be used to sort
    # @option opts [String] :dir the direction of the sort
    # @option opts [Integer] :limit the maximum number of record to return  
    # @option opts [Integer] :offset the number of records to skip
    # @option opts [Integer] :start alias for :offset 
    # @option opts [Mixed] Any option recognised by ActiveRecord::Base.find
    # @return [Hash] ExtJS compliant response containing the requested records
    #   :success : normally always true (even if no record send)
    #   :total : the number of total records (ignoring limits)
    #   :data : an array of records
    #   :message : optional messages
    def ext_read(opts = {})
      opts = filter_unsupported_options :ext_read, opts
      er = ExtResponse.new
      opts = filter_sort opts 

      if opts[:limit] != nil 
          if opts[:start] != nil
            opts[:offset] = opts.delete :start
          end
          total = get_total_count opts.clone # total must contains the total number of record without limit/offset
      end

      list = self.find(:all, opts)
      list.each do |r|
        s = r.attributes
        if(opts[:include] != nil)   # add assotiations if requested {attr_id, attr : {id: ...
          opts[:include].each do |j|
            s[j.to_s] = r.send(j).attributes
          end
        end
        er.add_data s
      end

      er.add(:total, total || er.data.length)
      er.to_hash
    end

    # Helper method : create a single record
    # If provided with a "id" attributes, it will be ignored
    #
    # @param [Hash] a record to create
    # @return [Hash] a hash containng the new record's attribute including the new id.
    # @private
    def ext_create_record(record = {})
      ar = self.new
      record.each_pair do |key, value|
        if(key != "id")
          sym = (key+"=").to_sym
          ar.send sym, value 
        end
      end
      ar.save
      ar.attributes
    end

    # Create one or several records
    # Responds to creation requests from an ExtJS Store
    #
    # @param [Hash] the request options
    # @option opts [Array] :data an array of record to create
    # @option opts [Hash] :data a record to create
    # @return [Hash] ExtJS compliant response containing the created records (with id)
    #   :success : true if one or more record were created 
    #   :data : an array of records
    #   :message : optional messages

    def ext_create(opts = {})
      raise "No data arguments in request" if opts[:data] == nil
      opts = filter_unsupported_options :ext_create, opts
      er = ExtResponse.new
      new_records = opts[:data]
      created = []

      if(new_records.kind_of? Array) 
        new_records.each do |r|
          begin
            new_record = ext_create_record r
            er.add_data(new_record)
            created.push(new_record["id"])
          rescue
            er.add_message "Warning : Could not create record #{r.to_s}. #{$!}\r\n"
          end
        end
      else
        r = new_records 
        begin
          new_record = ext_create_record r
          er.add_data(new_record)
          created.push(new_record["id"])
        rescue
          er.add_message "Warning : Could not create record #{r.to_s}. #{$!}\r\n"
        end
      end

      if created.length > 0
        er.add_message "Successfully created #{created.length} records with id : " + created.join(', ')
        er.success = true
      else
        er.add_message "No record created."
        er.success = false
      end
      er.to_hash 
    end

    # Helper method : update a single record
    #
    # @param [Hash] record the record to update. It can contain a full record or just some attributes and an id
    # @param [optional Hash] options regarding record creation
    # @option options [String] :on_edit 
    #   "find_or_create" on a secondary model update, it will try to find an existing record with the value or will create a new one. 
    #   "force_create" will always result in a new record creation
    # @return [Hash] the attributes of the updated models with optional secondary models attributes.
    # @private
    def ext_update_record(record = {}, options = {})
      secondary_models = []
      raise "Record is empty" if record == {} 
      ar = self.find(record["id"])

      record.each_pair do |key, value|
        key_array = key.split(".")
        if(key_array.length > 1)
          sm = (key_array[0, key_array.length - 1])
          secondary_models.push sm

          if options[:on_edit] == "find_or_create" 
            #try to find an existing model that match the new value 
            #TODO : this could be replace by find_or_create_by_xxxx
            m = Kernel.const_get(sm[- 1].capitalize).find(:first, {:conditions => {key_array[-1].to_sym => value}})
            if !m
              sm_clone = sm.clone
              sm_clone.push "clone" 
              m = call_func(ar, sm_clone)
            end
            call_func(ar, sm, m)          # assign the new secondary model (replace the old)

          elsif options[:on_edit] == "force_create" # force create a new item
            sm_clone = sm.clone
            sm_clone.push "clone" 
            m = call_func(ar, sm_clone)
            call_func(ar, sm, m)  
          end

        end
        call_func(ar, key_array, value)
      end
      ar.save                             #save the primary model

      secondary_models.each do |model|    #save the secondary models
        model.push('save')
        call_func(ar, model)
      end

      s = ar.attributes
      if(options[:include] != nil)        # add assotiations if requested {attr_id, attr : {id: ...
        options[:include].each do |j|
          s[j] = ar.send(j).attributes
        end
      end

      s  
    end
    
    # Update one or several records
    # Responds to update requests from an ExtJS Store
    #
    # @param [Hash] the request options
    # @option opts [Array] :data an array of record to update
    # @option opts [Hash] :data a record to update
    # @option options [String] :on_edit 
    #   "find_or_create" on a secondary model update, it will try to find an existing record with the value or will create a new one. 
    #   "force_create" will always result in a new record creation
    #   When one of those are not provided, the default is to update the current record.
    # @return [Hash] ExtJS compliant response containing the updated records (with id)
    #   :success : true if one or more record were updated
    #   :data : an array of records
    #   :message : optional messages
    def ext_update(opts = {})
      raise "No data arguments in request" if opts[:data] == nil
      opts = filter_unsupported_options :ext_update, opts
      er = ExtResponse.new
      records = opts[:data]
      updated = []

      if(records.kind_of? Array)
        records.each do |r|
          begin
            er.add_data(ext_update_record r, opts)
            updated.push r["id"]
          rescue
            er.add_message "Warning : Could not update record with id #{r["id"]}. #{$!}"
            raise
          end
        end
      else
        r = records 
        begin
          er.add_data(ext_update_record r, opts)
          updated.push r["id"]
        rescue
          er.add_message "Warning : Could not update record with id #{r["id"]}. #{$!}\r\n"
        end
      end

      if updated.length > 0
        er.add_message "Successfully updated #{updated.length} records with id : " + updated.join(', ')
        success = true
      else
        er.add_message "No record updated."
        success = false
      end

      er.success = success 
      er.to_hash
    end

    # Delete one or several records
    # Responds to update requests from an ExtJS Store
    #
    # @param [Hash] the request options
    # @option opts [Array] :data an array of record to delete
    # @option opts [Hash] :data a record to delete 
    # @return [Hash] ExtJS compliant response contaning a message
    #   :success : true if one or more record were deleted
    #   :data : an array of records
    #   :message : optional messages
    def ext_destroy(opts = {})
      raise "No data arguments in request" if opts[:data] == nil
      opts = filter_unsupported_options :ext_destroy, opts
      record_ids = opts[:data]
      er = ExtResponse.new
      deleted = []

      if(record_ids.kind_of? Array) 
        record_ids.each do |id|
          begin
            raise "record not found" if self.delete(id) == 0
            deleted.push(id)
          rescue
            er.add_message "Warning : Could not destroy record with id #{id} : #{$!}\r\n"
          end
        end
      else
        begin
          raise "record not found" if self.delete(record_ids) == 0
          deleted.push(record_ids)
        rescue
          er.add_message "Warning : Could not destroy record with id #{record_ids} : #{$!}\r\n"
        end
      end

      if deleted.length > 0
        er.add_message "Successfully deleted #{deleted.length} records with id : " + deleted.join(', ')
        er.success = true
      else
        er.add_message "No record deleted."
        er.success = false
      end
      er.to_hash
    end    

    def ext_node_is_leaf(level, opts) 
      opts[:tree_nodes][level+1] == nil ? true : false
    end

    def ext_get_node_info(node) 
      m = node.match(/(\d+)_(\w+)_(\d+)/)
      node = {:level => m[1].to_i, :model => m[2], :id => m[3].to_i}
    end

    def ext_get_child_nodes(opts = {})
      parent_node = ext_get_node_info(opts[:node])
      level = parent_node[:level] + 1
      parent_cfg = opts[:tree_nodes][parent_node[:level]] 
      node_cfg = opts[:tree_nodes][parent_node[:level]+1] 
      parent_model = Kernel.const_get(parent_node[:model]).find(parent_node[:id])
      n = [node_cfg[:link], [node_cfg[:text], "id", "class"]]
      node_info = call_func parent_model, n 
      nodes = []
      if node_info.kind_of? Array
        node_info.each do |x|
          node = {
            :text => x[node_cfg[:text]],
            :id => level.to_s + "_"+x["class"].name+"_"+x["id"].to_s
          }
          node[:cls] = node_cfg[:cls] if node_cfg[:cls]
          node[:leaf] = ext_node_is_leaf(level, opts)
          nodes.push node 
        end
      else
      node = {
         :text => node_info[node_cfg[:text]],
         :id => level.to_s + "_"+node_info["class"].name+"_"+node_info["id"].to_s
      }
      node[:cls] = node_cfg[:cls] if node_cfg[:cls]
      node[:leaf] = ext_node_is_leaf(level, opts)
      nodes.push node 
      end
      nodes
    end

    def ext_get_root_nodes(opts = {})
      cfg = opts[:tree_nodes][0]
      raise "A :text attributes must de defined in each node configurations" if !cfg[:text]
      records = self.find(:all, opts[:root])
      nodes = []
      records.each do |r|
        node = {
          :text => call_func(r, cfg[:text]),
          :id => "0_"+self.name+"_"+r.id.to_s
        }
        node[:cls] = cfg[:cls] if cfg[:cls]
        node[:leaf] = ext_node_is_leaf(0, opts)
        nodes.push node
      end
      nodes
    end

    def ext_get_nodes(opts = {})
      raise "A tree_nodes configuration item is required" if opts[:tree_nodes] == nil 
      if opts[:node] == nil
        ext_get_root_nodes opts
      else
        ext_get_child_nodes opts 
      end
    end

  end

end

ActiveRecord::Base.send :include, ActiveExtAPI

