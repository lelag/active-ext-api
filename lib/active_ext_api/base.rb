module ActiveExtAPI
  # Generic Active Ext API exception class.
  # @author Le Lag
  class ActiveExtAPIError < StandardError
  end

  # Base Class for Active Ext API
  # @author Le Lag
  class Base
    EXT_SUPPORTED_OPTIONS = {
      :ext_read => [:limit, :offset, :start, :sort, :dir, :conditions, :order, :group, :having, :joins, :include, :select, :from, :readonly, :lock],
      :ext_create => [:data],
      :ext_update => [:data, :on_edit],
      :ext_destroy => [:data] }

    def initialize(ar_model)
      @response = ExtResponse.new
      @active_record_model = ar_model
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

    # Generate a random string of alphanumeric characters
    #
    # @param [Integer] the size of the wanted string (defaults to 3)
    # @return [String] a random string
    def random_string(size = 3) 
      b =  (48..57).to_a + (65..90).to_a + (97..122).to_a
      (0...size).collect { b[Kernel.rand(b.length)].chr }.join
    end

  end
end
