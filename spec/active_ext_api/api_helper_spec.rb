module ActiveDirect
  class Config
    attr_accessor :method_config
    class << self
      def method_config
        @@method_config ||= Hash.new { |hash, key| hash[key] = [] }
      end
    end
  end
end

require File.dirname(__FILE__) + '/../spec_helper'
describe ActiveExtAPI::StoreRead, "helper methods" do

  context "filter_sort_tables" do
    it "should transform a string send by ext :sort into tables name" do
        r = ActiveExtAPI::StoreRead.new Book
        r.filter_sort_tables("name").should == "name"
        r.filter_sort_tables("artist.name").should == "artists.name"
        r.filter_sort_tables("artist.country.name").should == "countries.name"
    end
  end
end


describe ActiveExtAPI::Base, "helper methods" do
  context "call_func" do
    it "should set a property on a chain of Active Directory association" do
      loan = double()
      book = double()
      author = double()
      loan.stub(:book).and_return(book)
      book.stub(:author).and_return(author)
      author.should_receive(:name=).with("the new name")
      m = "book.author.name".split(".")
      r = ActiveExtAPI::Base.new Loan 
      r.call_func(loan, m, "the new name")
    end

    it "should call a method when no value is given " do
      author = double()
      loan = double()
      book = double()
      loan.stub(:book).and_return(book)
      book.stub(:author).and_return(author)
      author.should_receive(:save)
      m = ["book", "author", "save"]
      r = ActiveExtAPI::Base.new Loan 
      r.call_func(loan, m)
    end
  end

  context "filter_unsupported_options" do
    it "should remove options that are not allowed in the global EXT_SUPPORTED_OPTIONS" do
      o = {:data => "stuff", :unsupported => "other stuff"}
      r = ActiveExtAPI::Base.new Loan 
      r.filter_unsupported_options(:ext_destroy, o).should == {:data=>"stuff"}
    end
  end

end

describe ActiveExtAPI::ClassMethods do
  context "acts_as_direct_ext_api : ActiveDirect integration" do
    it "should add the ext api methods to the ActiveDirect::Config object" do
    expected_config = [{"name"=>"ext_read", "len"=>1},
    {"name"=>"ext_create", "len"=>1},
    {"name"=>"ext_update", "len"=>1},
    {"name"=>"ext_destroy", "len"=>1}]
      Loan.acts_as_direct_ext_api
      ActiveDirect::Config.method_config[Loan.to_s].length.should == 7
    end
  end
end
