module ActiveExtAPI
  # Small Helper class to create response that can be understood by ExtJS's stores
  # It will always return a hash with
  #   - a success (default to true)
  #   - a list of message
  #   - a data field
  # and optionally extra arguments that can be set
  # The hash return by this class must be turned into json or xml before sending to the client
  # @author Le Lag
  class ExtResponse 
    attr_accessor :success, :data, :messages, :extra_parameters

    def initialize(success = true)
      @messages = []
      @data = []
      @extra_parameters = {}
      @success = success 
    end

    def data_to_hash
        if @data.length == 1
          @data[0]
        else
          @data
        end
    end

    def to_hash 
      @extra_parameters.merge!({:success=>@success, :message=>@messages.join("\r\n"), :data=>data_to_hash})
    end

    def add_message msg
      @messages.push msg
    end

    def add_data data 
      @data.push data
    end

    def add(sym, data)
      @extra_parameters[sym] = data 
    end

  end
end
