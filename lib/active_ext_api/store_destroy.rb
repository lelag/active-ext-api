module ActiveExtAPI
  # Ext Store Read API 
  # This class provides an api to process deletion requested by ExtJS Stores
  # @author Le Lag
  class StoreDestroy < Base
    # Delete one or several records
    # Responds to destroy requests from an ExtJS Store
    #
    # @param [Hash] the request options
    # @option opts [Array] :data an array of record to delete
    # @option opts [Hash] :data a record to delete 
    # @return [Hash] ExtJS compliant response contaning a message
    #   :success : true if one or more record were deleted
    #   :data : an array of records
    #   :message : optional messages
    def destroy(opts = {})
      raise "No data arguments in request" if opts[:data] == nil
      opts = filter_unsupported_options :ext_destroy, opts
      record_ids = opts[:data]
      deleted = []

      if(record_ids.kind_of? Array) 
        record_ids.each do |id|
          begin
            raise "record not found" if @active_record_model.delete(id) == 0
            deleted.push(id)
          rescue
            @response.add_message "Warning : Could not destroy record with id #{id} : #{$!}\r\n"
          end
        end
      else
        begin
          raise "record not found" if @active_record_model.delete(record_ids) == 0
          deleted.push(record_ids)
        rescue
          @response.add_message "Warning : Could not destroy record with id #{record_ids} : #{$!}\r\n"
        end
      end

      if deleted.length > 0
        @response.add_message "Successfully deleted #{deleted.length} records with id : " + deleted.join(', ')
        @response.success = true
      else
        @response.add_message "No record deleted."
        @response.success = false
      end
      @response.to_hash
    end    

  end
end
