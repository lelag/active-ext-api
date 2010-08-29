module ActiveExtAPI
  # Ext Tree API 
  # This class provides an api to link an ActiveRecord model with ExtJS Trees.
  # @author Le Lag
  class Tree < Base

    # Return whether a node in a leaf. 
    #
    # @param [Integer] The current level in the tree 
    # @param [Hash] the tree configuration. A :tree_nodes options is required.
    # @return [Boolean] true if the node is leaf, false if it's not.
    def node_is_leaf(level, opts) 
      opts[:tree_nodes][level+1] == nil ? true : false
    end

    # Return a node info based on it's node id 
    #
    # @param [String] the node id with a format #level_#ModelName_#id or "root" for the root node.
    # @return [Hash] A hash with the node info 
    def get_node_info(node) 
      m = node.match(/(\d+)_(\w+)_(\d+)/)
      node = {:level => m[1].to_i, :model => m[2], :id => m[3].to_i}
    end

    # Return a node's children records as tree node as expected by Ext.tree.TreeLoader
    #
    # @param [String] the node id with a format #level_#ModelName_#id or "root" for the root node.
    # @param [Hash] the tree configuration. A :tree_nodes options is required.
    # @return [Array] an array of nodes
    def get_child_nodes(node, opts = {})
      parent_node = get_node_info(node)
      level = parent_node[:level] + 1
      raise "This level is not setup in tree config" if opts[:tree_nodes][level] == nil
      parent_cfg = opts[:tree_nodes][parent_node[:level]] 
      node_cfg = opts[:tree_nodes][level] 
      if node_cfg[:go_to_level] != nil #recursion mecanism
        level = node_cfg[:go_to_level]
        node_cfg = opts[:tree_nodes][level] 
      end
      parent_model = Kernel.const_get(parent_node[:model]).find(parent_node[:id])
      n = [node_cfg[:link], [node_cfg[:text], "id", "class"]]
      node_info = call_func parent_model, n 
      nodes = []
      if node_info.kind_of? Array
        node_info.each do |x|
          node = {
            :text => x[node_cfg[:text]],
            :id => level.to_s + "_"+x["class"].name+"_"+x["id"].to_s+"?"+random_string
          }
          node[:cls] = node_cfg[:cls] if node_cfg[:cls]
          node[:leaf] = node_is_leaf(level, opts)
          nodes.push node 
        end
      else
        node = {
          :text => node_info[node_cfg[:text]],
          :id => level.to_s + "_"+node_info["class"].name+"_"+node_info["id"].to_s+"?"+random_string
        }
        node[:cls] = node_cfg[:cls] if node_cfg[:cls]
        node[:leaf] = node_is_leaf(level, opts)
        nodes.push node 
      end
      nodes
    end

    # Return the tree root's children records as tree node as expected by Ext.tree.TreeLoader
    #
    # @param [String] the node id with a format #level_#ModelName_#id or "root" for the root node.
    # @param [Hash] the tree configuration. A :tree_nodes options is required with at least 1 level.
    # @return [Array] an array of nodes
    def get_root_nodes(opts = {})
      cfg = opts[:tree_nodes][0]
      raise "A :text attributes must de defined in each node configurations" if !cfg[:text]
      records = @active_record_model.find(:all, opts[:root_options])
      nodes = []
      records.each do |r|
        node = {
          :text => call_func(r, cfg[:text]),
          :id => "0_"+@active_record_model.name+"_"+r.id.to_s
        }
        node[:cls] = cfg[:cls] if cfg[:cls]
        node[:leaf] = node_is_leaf(0, opts)
        nodes.push node
      end
      nodes
    end
  
    # Return records as tree node as expected by Ext.tree.TreeLoader
    #
    # @param [String] the node id with a format #level_#ModelName_#id or "root" for the root node.
    # @param [Hash] the tree configuration. A :tree_nodes options is required.
    #     A tree_config contains an array of hash for each level in the tree
    #     A node level configuration contains any Ext.tree.TreeNode config
    #       and a link (ActiveRecord relation).
    #     A treenode config can simply be a go_to_level options that allow for recursion in tree
    # @return [Array] an array of nodes
    def get_nodes(node = "" , opts = {})
      node = "root" if node == ""
      raise "A tree_nodes configuration item is required" if opts[:tree_nodes] == nil 
      if node == "root" 
        get_root_nodes opts
      else
        get_child_nodes node, opts 
      end
    end
  
  end
end
