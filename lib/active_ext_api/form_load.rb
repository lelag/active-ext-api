module ActiveExtAPI
  # Ext Form API
  # This class provides generic load functionnality
  # for Ext Form to load records from ActiveRecords models.
  # @author Le Lag
  class FormLoad < StoreRead 

    def load(id, opts = {})
      begin
      raise "An ID is required !" if id == nil
      # try to find the record for the give id
        r = @active_record_model.find(id, opts)
        s = r.attributes
        @response.add_data (s.merge get_association_items(r, opts) )
      rescue
        @response.success = false
        @response.add(:errorMessage, "#{$!}") 
      end
      return @response.to_hash
    end
  end
end
