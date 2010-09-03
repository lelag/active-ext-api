module ActiveExtAPI
  # Ext Form API
  # This class provides generic load ands submit functionnality
  # for Ext Form to load records from ActiveRecords models.
  # @author Le Lag
  class Form < Base

    def load(opts = {})
      begin
      raise "An ID is required !" if !opts.has_key? :id
      # try to find the record for the give id
        id = opts.delete(:id)
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
