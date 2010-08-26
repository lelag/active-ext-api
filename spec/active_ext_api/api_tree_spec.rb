require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveExtAPI::ClassMethods, "ext_get_nodes" do
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

    it "it should return the list of all items when given a root node id" do
      r = Book.ext_get_nodes("root", @baseParams)
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
      r = Book.ext_get_nodes("0_Book_1", @baseParams)
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
      r = Author.ext_get_nodes("0_Author_2", @baseParams)
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

    it "should return an error when accessing a level that is not set up" do
      lambda {
        r = Author.ext_get_nodes("1_Book_2", @baseParams)
      }.should raise_error "This level is not setup in tree config"
    end
end
  context "with 2 models and recursion : go_to_level => 0" do
    before(:each) do
      @baseParams = {
        :tree_nodes => [
          {
            :link => "author",
            :cls => "personn_cls",
            :text => "name"
          },{
            :link => "books",
            :cls => "book_cls",
            :text => "title"
          },{
            :go_to_level => 0
          }
        ]
      }
      @r = Author.ext_get_nodes("1_Book_3", @baseParams)
    end
    it "should return the books author name and reset to level 0" do
      @r.should be_a_kind_of Array
      @r.count.should == 1 
      b = Book.find(3)
      r = @r[0]
      r[:text].should == b.author.name
    end
    it "should return a different id for identical nodes" do
      @r.should be_a_kind_of Array
      @r.count.should == 1 
      r1 = @r[0]
      @r = Author.ext_get_nodes("1_Book_3", @baseParams)
      r2 = @r[0]
      r1[:id].should_not == r2[:id]
    end
  end
end
