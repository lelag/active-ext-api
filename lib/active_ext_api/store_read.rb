module ActiveExtAPI
  # Ext Store Read API 
  # This class provides an api to send ActiveRecord model records to ExtJS Stores
  # @author Le Lag
  class StoreRead < Base

    # Get the total count for a find query ignoring limits
    # @param [Hash] opts the options for a ActiveRecord::Base.find call
    # @return [Integer] the total number of rows for the query ignoring limit and offset
    def get_total_count(opts = {}) 
        opts[:limit] = nil
        opts[:offset] = nil
        opts[:order] = nil
        @active_record_model.count(opts)
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
    def read(opts = {})
      opts = filter_unsupported_options :ext_read, opts
      opts = filter_sort opts 

      if opts[:limit] != nil 
          if opts[:start] != nil
            opts[:offset] = opts.delete :start
          end
          total = get_total_count opts.clone # total must contains the total number of record without limit/offset
      end

      list = @active_record_model.find(:all, opts)
      list.each do |r|
        s = r.attributes
        @response.add_data (s.merge get_association_items(r, opts))
      end

      @response.add(:total, total || @response.data.length)
      @response.to_hash
    end
    
  end
end
