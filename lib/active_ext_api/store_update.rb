module ActiveExtAPI
  # Ext Store Update API 
  # This class provides an api to process updates requested by ExtJS Stores
  # @author Le Lag
  class StoreUpdate < Base
    # Update a single record
    #
    # @param [Hash] record the record to update. It can contain a full record or just some attributes and an id
    # @param [optional Hash] options regarding record creation
    # @option options [String] :on_edit 
    #   "find_or_create" on a secondary model update, it will try to find an existing record with the value or will create a new one. 
    #   "force_create" will always result in a new record creation
    # @return [Hash] the attributes of the updated models with optional secondary models attributes.
    # @private
    def update_record(record = {}, options = {})
      secondary_models = []
      raise "Record is empty" if record == {} 
      ar = @active_record_model.find(record["id"])

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
      return s  
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
    def update(opts = {})
      raise "No data arguments in request" if opts[:data] == nil
      opts = filter_unsupported_options :ext_update, opts
      records = opts[:data]
      updated = []

      if(records.kind_of? Array)
        records.each do |r|
          begin
            @response.add_data(update_record r, opts)
            updated.push r["id"]
          rescue
            @response.add_message "Warning : Could not update record with id #{r["id"]}. #{$!}"
            raise
          end
        end
      else
        r = records 
        begin
          @response.add_data(update_record r, opts)
          updated.push r["id"]
        rescue
          @response.add_message "Warning : Could not update record with id #{r["id"]}. #{$!}\r\n"
        end
      end

      if updated.length > 0
        @response.add_message "Successfully updated #{updated.length} records with id : " + updated.join(', ')
        success = true
      else
        @response.add_message "No record updated."
        success = false
      end

      @response.success = success 
      @response.to_hash
    end


  end
end
