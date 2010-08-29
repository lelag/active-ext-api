module ActiveExtAPI
  # Ext Store Read API 
  # This class provides an api to process record creation requested by ExtJS Stores
  # @author Le Lag
  class StoreCreate < Base

    # Create a single record
    # If provided with a "id" attributes, it will be ignored
    #
    # @param [Hash] a record to create
    # @return [Hash] a hash containng the new record's attribute including the new id.
    # @private
    def ext_create_record(record = {})
      ar = @active_record_model.new
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
    def create(opts = {})
      raise "No data arguments in request" if opts[:data] == nil
      opts = filter_unsupported_options :ext_create, opts
      new_records = opts[:data]
      created = []

      if(new_records.kind_of? Array) 
        new_records.each do |r|
          begin
            new_record = ext_create_record r
            @response.add_data(new_record)
            created.push(new_record["id"])
          rescue
            @response.add_message "Warning : Could not create record #{r.to_s}. #{$!}\r\n"
          end
        end
      else
        r = new_records 
        begin
          new_record = ext_create_record r
          @response.add_data(new_record)
          created.push(new_record["id"])
        rescue
          @response.add_message "Warning : Could not create record #{r.to_s}. #{$!}\r\n"
        end
      end

      if created.length > 0
        @response.add_message "Successfully created #{created.length} records with id : " + created.join(', ')
        @response.success = true
      else
        @response.add_message "No record created."
        @response.success = false
      end
      @response.to_hash 
    end
    

  end
end
