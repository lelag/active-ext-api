# ActiveExtAPI is a module that inject methods to an ActiveRecord model 
# that implements an API that can be used to communicate with an ExtJS Store's CRUD API.
# It will add the following 4 methods :
#   - ext_read : used to load a store
#   - ext_create : used to create records
#   - ext_update : used to update records
#   - ext_delete : used to delete records
# @author Le Lag
module ActiveExtAPI 
  DEFAULT_METHODS = { 'ext_read' => 1, 'ext_create' => 1, 'ext_update' => 1, 'ext_destroy' => 1, 'ext_get_nodes'=> 2 }

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

    # Private proxy for private ActiveRecord method construct_finder_sql
    def _ext_api_construct_finder_sql(opts = {})
      construct_finder_sql(opts)
    end

    
    # Return a list of records that can be used to load an ExtJS Store
    #
    # ActiveRecord alias to ActiveExtAPI::Read.read
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
      ext_api = ActiveExtAPI::StoreRead.new self
      ext_api.read opts
    end

    # Create one or several records
    # Responds to creation requests from an ExtJS Store
    #
    # ActiveRecord alias for ActiveExtAPI::Create.create
    #
    # @param [Hash] the request options
    # @option opts [Array] :data an array of record to create
    # @option opts [Hash] :data a record to create
    # @return [Hash] ExtJS compliant response containing the created records (with id)
    #   :success : true if one or more record were created 
    #   :data : an array of records
    #   :message : optional messages
    def ext_create(opts = {})
      ext_api = ActiveExtAPI::StoreCreate.new self
      ext_api.create opts
    end


    
    # Update one or several records
    # Responds to update requests from an ExtJS Store
    #
    # ActiveRecord alias for ActiveExtAPI::Update.update
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
      ext_api = ActiveExtAPI::StoreUpdate.new self
      ext_api.update opts
    end

    # Delete one or several records
    # Responds to destroy requests from an ExtJS Store
    #
    # ActiveRecord alias for ActiveExtAPI::Destroy.destroy
    #
    # @param [Hash] the request options
    # @option opts [Array] :data an array of record to delete
    # @option opts [Hash] :data a record to delete 
    # @return [Hash] ExtJS compliant response contaning a message
    #   :success : true if one or more record were deleted
    #   :data : an array of records
    #   :message : optional messages
    def ext_destroy(opts = {})
      ext_api = ActiveExtAPI::StoreDestroy.new self
      ext_api.destroy opts
    end    


    # Return records as tree node as expected by Ext.tree.TreeLoader
    #
    # ActiveRecord alias for ActiveExtAPI::Tree.get_nodes
    #
    # @example Tree Configuration Example
    #   
    #   root id must be root :
    #   root:{text:"whatever", id:"root"}
    #
    #   loader config : 
    #   loader: {
    #       directFn: App.models.Model.ext_get_nodes, // requires Active Direct plugin
    #       paramOrder: ["tree_config"],              // necessary to use for baseParams to be send
    #        baseParams: {
    #          "root_options" : {}      //ActiveRecord::Base.find options goes here
    #          "tree_config": {
    #            "tree_nodes": [
    #              {
    #                "cls":"category_cls",
    #                "text":"name"
    #              },
    #              {
    #                "link":"radios",
    #                "cls":"radio_cls",
    #                "text":"name"
    #              },{
    #                "go_to_level":0 //recursion (requires that the node 0 has a link option.
    #             }
    #            ]
    #       ...
    #
    #
    # @param [String] the node id with a format #level_#ModelName_#id or "root" for the root node.
    # @param [Hash] the tree configuration. A :tree_nodes options is required.
    # @return [Array] an array of nodes
    def ext_get_nodes(node = "" , opts = {})
      ext_api = ActiveExtAPI::Tree.new self
      ext_api.get_nodes node, opts
    end

  end

end

ActiveRecord::Base.send :include, ActiveExtAPI

