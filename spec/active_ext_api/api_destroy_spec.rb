require File.dirname(__FILE__) + '/../spec_helper'
require 'pp'

describe "ActiveExtAPI::ClassMethods.ext_destroy" do
  context "with no :data argument" do
    it "should raise an error"  do
      lambda { Book.ext_destroy }.should raise_error
    end 
  end
  context "with a hash as :data argument" do
    it "should return :success => false if no record where delete" do
      r = User.ext_destroy({:data => {:non_sense=>999}})
      r[:success].should == false
      r = User.ext_destroy({:data => 999})
      r[:success].should == false
    end

    it "should delete a record" do
      lambda { User.find(1) }.should_not raise_error
      r = User.ext_destroy({:data => 1})
      r[:success].should == true 
      lambda { User.find(1) }.should raise_error
    end
  end

  context "with an array as :data argument" do
    it "should return :success => false if no record where delete" do
      r = User.ext_destroy({:data => [990, 991, 992]})
      r[:success].should == false
    end

    it "should delete existing record and ignore the other" do
        [4,5,6].each { |id|
          lambda {  Author.find(id) }.should_not raise_error
        }
        lambda {  Author.find(999) }.should raise_error
        r = Author.ext_destroy({:data=>[4,5,6,999]})
        r[:success].should == true
        [4,5,6].each { |id|
          lambda {  Author.find(id) }.should raise_error
        }
    end

  end

end
