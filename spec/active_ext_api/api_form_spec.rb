require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveExtAPI::ClassMethods, "ext_form_load" do
  before(:each) do
    
  end
  context " with an id as parameter" do
    it "should return an error message if the record does not exists" do
      r = Book.ext_form_load()
      r[:success].should == false
      r.should have_key :errorMessage
      r[:errorMessage].should be_a_kind_of String
      r = Book.ext_form_load({:id=>4599})
      r[:success].should == false
      r.should have_key :errorMessage
      r[:errorMessage].should be_a_kind_of String
    end

    it "should return a records field in the data field" do
      r = Book.ext_form_load({:id=>4})
      r[:success].should == true 
      r.should have_key :data
      b = Book.find(4)
      r[:data].each_pair do |k,v|
        v.should == b.send(k)
      end
    end

    it "should return a record's associated model's field" do
      r = Book.ext_form_load({:id=>4, :include=>[:author]})
      r[:success].should == true 
      r.should have_key :data
      b = Book.find(4)
      author = r[:data]["author"]
      author["name"].should == b.author.name
    end

    it "should return an array of linked record when a records has_many included children" do
      r = Author.ext_form_load({:id=>3, :include=>[:books]})
      r[:success].should == true 
      r.should have_key :data
      data = r[:data]
      data.should have_key "books"
      data["books"].should be_a_kind_of Array
      a = Author.find(3)
      ab = a.books
      ab.each do |i|
        book_found = false
        data["books"].each do |db|
          if db["id"] == i.id
            book_found = true
          end
        end
        book_found.should == true
      end

    end
  end
end
