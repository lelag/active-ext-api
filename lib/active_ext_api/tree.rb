module ActiveExtAPI
  # Ext Tree API 
  # This class provides an api to link an ActiveRecord model with ExtJS Trees.
  # @author Le Lag
  class Tree < Base

    # Return whether a node in a leaf. 
    #
    # @param [Integer] The current level in the tree 
    # @param [ActiveRecord::Base] the ActiveRecord for the node. (optional)
    # @return [Boolean] true if the node is leaf, false if it's not.
    def node_is_leaf?(level, node = nil) 
      if node != nil && l = next_level_is_goto?(level)
        link = @tree_nodes[l][:link] # the next level link
        if node[link] != nil && node[link].length > 0 # if the record has children
          false 
        else
          true 
        end
      else
        @tree_nodes[level+1] == nil ? true : false
      end
    end

    # Return whether the next level is a goto step
    #
    # @param [Integer] The current level in the tree
    # @return [Mixed] False if not a goto step, the goto index if it is.
    def next_level_is_goto?(level) 
      if @tree_nodes[level+1] != nil
        if @tree_nodes[level+1].has_key?(:go_to_level)
          return @tree_nodes[level+1][:go_to_level] 
        end
      end
      return false
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
    # @return [Array] an array of nodes
    def get_child_nodes(node)
      parent_node = get_node_info(node)
      level = parent_node[:level] + 1
      raise "This level is not setup in tree config" if @tree_nodes[level] == nil
      parent_cfg = @tree_nodes[parent_node[:level]] 
      node_cfg = @tree_nodes[level] 
      if node_cfg[:go_to_level] != nil #recursion mecanism
        level = node_cfg[:go_to_level]
        node_cfg = @tree_nodes[level] 
      end
      parent_model = Kernel.const_get(parent_node[:model]).find(parent_node[:id])
      n = [node_cfg[:link], [node_cfg[:text], "id", "class"]]
      if l = next_level_is_goto?(level)    # if the next step is goto, also return the link 
        n[1].push @tree_nodes[l][:link]
      end
      node_info = call_func parent_model, n 
      nodes = []
      if node_info.kind_of? Array
        node_info.each do |x|
          node = {
            :text => x[node_cfg[:text]],
            :id => level.to_s + "_"+x["class"].name+"_"+x["id"].to_s+"?"+random_string
          }
          node[:cls] = node_cfg[:cls] if node_cfg[:cls]
          node[:leaf] = node_is_leaf?(level, x)
          nodes.push node 
        end
      else
        node = {
          :text => node_info[node_cfg[:text]],
          :id => level.to_s + "_"+node_info["class"].name+"_"+node_info["id"].to_s+"?"+random_string
        }
        node[:cls] = node_cfg[:cls] if node_cfg[:cls]
        node[:leaf] = node_is_leaf?(level, node_info)
        nodes.push node 
      end
      nodes
    end

    # Return the tree root's children records as tree node as expected by Ext.tree.TreeLoader
    #
    # @return [Array] an array of nodes
    def get_root_nodes()
      cfg = @tree_nodes[0]
      raise "A :text attributes must de defined in each node configurations" if !cfg[:text]
      records = @active_record_model.find(:all, @root_options)
      nodes = []
      records.each do |r|
        node = {
          :text => call_func(r, cfg[:text]),
          :id => "0_"+@active_record_model.name+"_"+r.id.to_s
        }
        node[:cls] = cfg[:cls] if cfg[:cls]
        node[:leaf] = node_is_leaf?(0)
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
      @tree_nodes = opts[:tree_nodes]
      @root_options = opts[:root_options]
      if node == "root" 
        get_root_nodes 
      else
        get_child_nodes node 
      end
    end
  
  end
end
