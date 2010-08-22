require File.dirname(__FILE__) + '/../spec_helper'

describe "ActiveExtAPI::ClassMethods.ext_update" do

  context "with no argument" do
    it "should raise an error" do 
      lambda { Book.ext_update }.should raise_error
    end
  end

  context "with a hash as argument[:data] - single record update" do
    it "should return an error if the record has no id" do
        arg = {"name"=>"Stephen King"}
        r = Author.ext_update({:data=>arg})
        r[:success].should == false
    end
    it "should update a record given an id and a value to update" do
        arg = {"id"=>1, "name"=>"Stephen King"}
        author = Author.find(:first) 
        original_name = author.name
        arg["id"] = author.id
        r = Author.ext_update({:data=>arg})
        r[:success].should == true 
        author2 = Author.find(author.id) 
        author2.name.should == "Stephen King"
    end
    
    it "should return the record attributes in the :data field after an update" do
        arg = {"id"=>2, "name"=>"Yuriko M"}
        user = User.find(arg["id"])
        r = User.ext_update({:data=>arg})
        r[:success].should == true
        r[:data]["address"].should == user.address
    end

    it "should save linked model attributes by default (direct association)" do
        arg = {"id"=>4, "title"=>"Life, the Universe and everything", "author.name"=>"Douglas Noel Adams"}
        book = Book.find(arg["id"])
        original_title = book.title
        original_author_name = book.author.name
        r = Book.ext_update({:data=>arg})
        r[:success].should == true
        book2 = Book.find(arg["id"])
        book2.title.should_not == original_title
        book2.author.name.should_not == original_author_name
    end
    it "should save linked model attributes by default (indirect association)" do
        arg = {"id"=>2, "book.author.name"=>"Douglas N Adams"}
        loan = Loan.find(arg["id"])
        original_author_name = loan.book.author.name
        r = Loan.ext_update({:data=>arg})
        r[:success].should == true
        loan2 = Loan.find(arg["id"])
        loan2.book.author.name.should_not == original_author_name
    end
  end
  context "with an array as argument[:data] : multiple records update" do
    it "should return an error if no records were updated" do
        arg = [{"name"=>"Stephen King"},{"name"=>"Franz Kafka"},{"name"=>"Georges Perec"}]
        lambda { r = Author.ext_update({:data=>arg}) }.should raise_error
    end
    it "should update multiple records" do
        arg = [{"id"=>1, "name"=>"Addison Wesley Corp"},{"id"=>2, "name"=>"McGrow Hill Corp"},{"id"=>3, "name"=>"LDED Corp"}]
        original_name= []
        arg.each do |a|
          p = Publisher.find(a["id"])
          original_name[p.id] = p.name
        end
        r = Publisher.ext_update({:data=>arg})
        r[:success].should == true 
        arg.each do |a|
          p = Publisher.find(a["id"])
          p.name.should_not == original_name[a["id"]]
        end
    end
    it "should return an array of record with attributes in the :data field" do
        arg = [{"id"=>1, "name"=>"Addison Wesley"},{"id"=>2, "name"=>"McGrow Hill"},{"id"=>3, "name"=>"LDED"}]
        r = Publisher.ext_update({:data=>arg})
        r[:success].should == true 
        r[:data].each do |a|
          p = Publisher.find(a["id"])
          a["name"].should == p.name
        end
    end
    it "should save linked model attributes by default" do
        arg = [{"id"=>4, "author.name"=>"Douglas \"Got a towel\" Adams"},{"id"=>1, "author.name"=>"Jean Marie Rifflet"},{"id"=>5, "author.name"=>"Bjarne C++ Stroustrup"}]
        original_name= []
        arg.each do |a|
          p = Book.find(a["id"])
          original_name[p.id] = p.author.name
        end
        r = Book.ext_update({:data=>arg})
        r[:success].should == true
        arg.each do |a|
          p = Book.find(a["id"])
          p.author.name.should_not == original_name[a["id"]]
        end
    end
  end
  context "with an :on_edit=>\"find_or_create\" option" do
    it "should try to find an existing record to assign to the modified record" do
        arg = {"id"=>1, "author.name"=>"Hakon Wium Lie"}
        r = Book.ext_update({:data=>arg, :on_edit=>"find_or_create"})
        r[:success].should == true
        b = Book.find(arg["id"])
        b.author.id.should == 7
    end

    it "should create a new record if it could not find a matching record" do
        arg = {"id"=>1, "author.name"=>"Charle Baudelaire"}
        r = Book.ext_update({:data=>arg, :on_edit=>"find_or_create"})
        r[:success].should == true
        a = Author.find(:first, {:conditions => {:name => "Charle Baudelaire"}})
        b = Book.find(arg["id"])
        b.author.id.should == a.id 
    end

  end
  context "with an :on_edit=>\"force_create\" option" do
      it "should create a new record even if one exist with an identical value" do
        arg = {"id"=>1, "author.name"=>"Charle Baudelaire"}
        r = Book.ext_update({:data=>arg, :on_edit=>"force_create"})
        r[:success].should == true
        a = Author.find(:all, {:conditions => {:name => "Charle Baudelaire"}})
        a.length.should == 2
        b = Book.find(arg["id"])
        b.author.id.should == a[1].id 
      end

  end
end
