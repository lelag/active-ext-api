require File.dirname(__FILE__) + '/../spec_helper'

describe "ActiveExtAPI::ClassMethods.ext_get_nodes" do
  context "error specification" do
    it "should raise an error when no config is provided" do
      lambda { Book.ext_get_nodes }.should raise_error "A tree_nodes configuration item is required"
    end
  end

  context "With a simple 2 models configuration" do

    before(:each) do
      @baseParams = {
        :tree_nodes => [
          {
            :cls => "book_cls",
            :text => "title"
          },{
            :link => "author",
            :cls => "person_cls",
            :text => "name"
          }
        ]
      }
    end

    it "it should return the list of all items when no root options is given and no node is requested" do
      params = {}.merge!(@baseParams)
      r = Book.ext_get_nodes(params)
      r.should be_a_kind_of Array
      r.each do |b|
        b.should be_a_kind_of Hash
        b.should have_key :text
        b.should have_key :id
        b.should have_key :cls
        b.should have_key :leaf
        id = b[:id].match(/0_Book_(\d+)/)[1].to_i
        bb = Book.find(id)
        bb.title.should == b[:text]
        b[:cls].should == "book_cls"
        b[:leaf].should == false
      end
    end

    it "should return the list of all first level children nodes when given a node id" do
      params = {:node=>"0_Book_1"}.merge!(@baseParams)
      r = Book.ext_get_nodes(params)
      r.should be_a_kind_of Array
      r.each do |b|
        b.should be_a_kind_of Hash
        b.should have_key :text
        b.should have_key :id
        b.should have_key :cls
        b.should have_key :leaf
        id = b[:id].match(/1_Author_(\d+)/)[1].to_i
        bb = Author.find(id)
        bb.name.should == b[:text]
        b[:cls].should == "person_cls"
        b[:leaf].should == true 
      end
    end

  context "with 2 models with a collection" do
    before(:each) do
      @baseParams = {
        :tree_nodes => [
          {
            :cls => "personn_cls",
            :text => "name"
          },{
            :link => "books",
            :cls => "book_cls",
            :text => "title"
          }
        ]
      }
    end
    it "should return the list of all first level children nodes when given a node id" do
      params = {:node=>"0_Author_2"}.merge!(@baseParams)
      r = Author.ext_get_nodes(params)
      r.should be_a_kind_of Array
      r.each do |b|
        b.should be_a_kind_of Hash
        b.should have_key :text
        b.should have_key :id
        b.should have_key :cls
        b.should have_key :leaf
        id = b[:id].match(/1_Book_(\d+)/)[1].to_i
        bb = Book.find(id)
        bb.title.should == b[:text]
        b[:cls].should == "book_cls"
        b[:leaf].should == true 
      end

    end

      
    end

  end
end
