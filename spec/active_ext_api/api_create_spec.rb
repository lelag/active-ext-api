require File.dirname(__FILE__) + '/../spec_helper'
describe ActiveExtAPI::ClassMethods, "ext_create" do
  before(:each) do
    
  end
  context "when the argument has not a :data attributes" do
    it "should raise an error" do
      lambda { Book.ext_create }.should raise_error "No data arguments in request"
    end
  end
  context "with a hash as argument[:data] : single record creation" do
    it "should create a new record in the model" do
      User.find(:all, {:conditions=>"name = 'George Washington'"}).count.should == 0 
      r = User.ext_create({:data=>{"name"=>"George Washington", "address"=>"Somewhere in the US"}})
      r[:success].should be true
      User.find(:all, {:conditions=>"name = 'George Washington'"}).count.should == 1
    end
    it "should ignore any id parameter and let ActiveRecord create new records" do
      User.find(:all, {:conditions=>"name = 'Thomas Jefferson'"}).count.should == 0 
      r = User.ext_create({:data=>{"name"=>"Thomas Jefferson", "address"=>"Somewhere in the US", "id"=>500}})
      r[:success].should be true
      User.find(:all, {:conditions=>"name = 'Thomas Jefferson'"}).count.should == 1
      User.find(:first, {:conditions=>"name = 'Thomas Jefferson'"}).id.should_not == 500
    end

    it "should return the new id with the return data" do 
      User.find(:all, {:conditions=>"name = 'Benjamin Franklin'"}).count.should == 0 
      r = User.ext_create({:data=>{"name"=>"Benjamin Franklin", "address"=>"Somewhere in the US"}})
      r[:success].should be true
      User.find(:all, {:conditions=>"name = 'Benjamin Franklin'"}).count.should == 1
      r[:data]["id"].should == User.find(:first, {:conditions=>"name = 'Benjamin Franklin'"}).id
    end
    it "should not create records when unrecognised arguments are present" do
      User.find(:all, {:conditions=>"name = 'John Adams'"}).count.should == 0 
      r = User.ext_create({:data=>{"name"=>"John Adams", "address"=>"Somewhere in the US", "thingamabob"=>500}})
      r[:success].should be false
      User.find(:all, {:conditions=>"name = 'John Adams'"}).count.should == 0
    end
  end
  context "with an array as argument[:data] : multiple records creation" do
    before(:each) do

    end
    it "should create x records at a time if :data contains an array of x request" do
      data = [{"name"=>"Stieg Larson"},{"name"=>"Philippa Gregory"},{"name"=>"Carl Hiaasen"}]
      data.each {|author| Author.find(:all,{:conditions=>"name = '#{author["name"]}'"}).count.should == 0}
      r = Author.ext_create({:data=>data})
      r[:success].should be true
      data.each {|author| Author.find(:all,{:conditions=>"name = '#{author["name"]}'"}).count.should == 1}
    end
    it "should return an id for each created record" do
      data = [{"name"=>"Fredrick Brooks"},{"name"=>"Brian Kernighan"},{"name"=>"Erich Gamma"}]
      data.each {|author| Author.find(:all,{:conditions=>"name = '#{author["name"]}'"}).count.should == 0}
      r = Author.ext_create({:data=>data})
      r[:success].should be true
      r[:data].each do |author| 
        Author.find(:all,{:conditions=>"name = '#{author["name"]}'"}).each do |a|
          author.should have_key("id") 
          author["id"].should == a.id
        end
      end 
    end
    it "should ignore uncorrect request and try to create correct ones" do
      data = [{"name"=>"Ravi Sethi"},{"name"=>"Shelley Powers"},{"name"=>"Thomas Corme", "foo"=>"bar"}]
      data.each {|author| Author.find(:all,{:conditions=>"name = '#{author["name"]}'"}).count.should == 0}
      r = Author.ext_create({:data=>data})
      r[:success].should be true
      r[:data].count.should == 2
      r[:data].each do |author| 
        Author.find(:all,{:conditions=>"name = '#{author["name"]}'"}).each do |a|
          author.should have_key("id") 
          author["id"].should == a.id
        end
      end 
    end
    it "should return :success false is no records could be created" do
      data = [{"nameuuu"=>"Ravi Sethi"},{"nauuume"=>"Shelley Powers"},{"name"=>"Thomas Corme", "foo"=>"bar"}]
      r = Author.ext_create({:data=>data})
      r[:success].should be false
    end
  end
end
