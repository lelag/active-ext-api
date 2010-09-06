module ActiveExtAPI
  # Ext Form API
  # This class provides generic submit functionnality
  # for Ext Form to save records to ActiveRecords models.
  # @author Le Lag
  class FormSubmit < Base 

    def submit(opts = {})
      begin
        raise "Not Implemented"
      rescue
        @response.success = false
        @response.add(:errorMessage, "#{$!}") 
      end
      return @response.to_hash
    end
  end
end
