require File.dirname(__FILE__) + '/../spec_helper'

describe "ActiveExtAPI::ExtResponse" do
  before(:each) do
    @r = ActiveExtAPI::ExtResponse.new
  end
  context "initialize" do 
    it "should default to true" do
      @r.success.should == true 
    end
  end
  context "output : to_hash" do
    it "should return an hash with at least a :success, :message and :data key" do
      @r.to_hash.should have_key :success
      @r.to_hash.should have_key :message
      @r.to_hash.should have_key :data
    end
    it "should return a single objet if there is only one data" do
      @r.add_data 1
      @r.to_hash()[:data].should_not be_a_kind_of Array
    end
    it "should add extra parameters if any" do
      total = 5
      @r.add(:total, total)
      expected_result = {:success=>true, :message=>"", :data=>[],:total=>5}
      @r.to_hash.should == expected_result
    end
  end
  context "adding messages" do
    it "should add messages to the @message array" do
      msg1 ="message1"
      msg2 ="message2"
      @r.add_message msg1
      @r.should have(1).messages
      @r.add_message msg2
      @r.should have(2).messages
    end
    it "should return the messages in the message key of the hash" do
      @r.add_message "ext on rails rocks"
      out = @r.to_hash
      out[:message].should == "ext on rails rocks"
    end
  end
  context "adding data" do
    it "should add data to the @data array" do
      @r.add_data 1
      @r.add_data 1
      @r.should have(2).data
    end
    it "should add extra parameters" do
      total = 5
      @r.add(:total, total)
      @r.extra_parameters.should have_key(:total)
      @r.extra_parameters[:total].should == 5
    end
  end
      
end
