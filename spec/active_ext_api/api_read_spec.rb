require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveExtAPI::ClassMethods, "ext_read" do
  before(:each) do
    
  end
  context "with no argument" do
    it "should return a hash with a success, a message, a data and a total property" do
        result = Book.ext_read({})
        result.should be_a_kind_of(Hash)
        result.should have_key(:success)
        result.should have_key(:message)
        result.should have_key(:data)
        result.should have_key(:total)
    end

    it "should return all records for a model when no arguments in given" do
        result = Book.ext_read
        result[:data].length.should == Book.count
    end
    
    it "should return the number of total record in the total key" do
        result = Book.ext_read
        result[:total].should == Book.count
    end
    it "should return records with an id" do
        result = Book.ext_read
        result[:data].each do |r| 
          r.should have_key("id")
        end
    end
  end
  context "with a limit, offset" do
    it "should limit the number of return record to the specified limit" do
        result = Book.ext_read({:limit => 1})
        result[:data].should be_a_kind_of Hash
    end
    it "should return the total number of record without the limit in the :total key" do
        result = Book.ext_read({:limit => 1})
        result[:total].should == Book.count
    end
    it "should work if provided with a :start options instead of a :offset" do
        lambda {
          result = Book.ext_read({:limit => 1, :start => 1})
        }.should_not raise_error
    end
  end
  context "with an include list" do
    it "should include linked models objet attributes to the :data hash" do
        result = Book.ext_read({:include => [:author, :publisher]})
        result[:data].each do |r| 
          r.should have_key("author")
          r.should have_key("publisher")
          b = Book.find r["id"]
          r["author"]["name"].should == b.author.name
          r["publisher"]["name"].should == b.publisher.name
        end
    end
    it "should return an array of record for has_many assoc"  do
        result = Author.ext_read({:include => [:books]})
        result[:data].each do |r|
          a = Author.find r["id"]
          r.should have_key "books"
          a.books.each do |i|
            book_found = false
            r["books"].each do |db|
              if db["id"] == i.id
                book_found = true
              end
            end
            book_found.should == true
          end
        end
    end
  end
  context "with a sorting request" do
    it "should sort the results according to a sort option (model own attribute)" do
        result = Book.ext_read({:sort=>"title", :dir=>"ASC"})
        sorted_result=result[:data].sort do |x,y|
          x["title"] <=> y["title"]
        end
        result[:data].should == sorted_result
    end

    it "should sort the result according to a desc sort option and a direction (model own attributes)" do
        result = Book.ext_read({:sort=>"title", :dir=>"DESC"})
        sorted_result=result[:data].sort do |x,y|
          y["title"] <=> x["title"]
        end
        result[:data].should == sorted_result
    end

    it "should sort the result when given an arry of sort config" do
        result = Book.ext_read(:sort=>[{:sort=>"author_id", :dir=>"ASC"},{:sort=>"title", :dir=>"DESC"}])
        sorted_result=result[:data].sort do |x,y|
          if x["author_id"] == y["author_id"]
            y["title"] <=> x["title"]
          else
            x["author_id"] <=> y["author_id"]
          end
        end
        result[:data].should == sorted_result
    end


    it "should sort the results according to a sort option on an associated model included with :include" do
        result = Book.ext_read(:sort=>[{:sort=>"author.name", :dir=>"ASC"},{:sort=>"title", :dir=>"DESC"}], :include=>[:author])
        sorted_result=result[:data].sort do |x,y|
          if x["author"]["name"] == y["author"]["name"]
            y["title"] <=> x["title"]
          else
            x["author"]["name"] <=> y["author"]["name"]
          end
        end
        result[:data].should == sorted_result

    end
  end
  context "with argument that are not supported by ActiveDirect::Base.find" do
      it "should ignore the non-standard options such as on_edit" do
        lambda { result = Book.ext_read(:on_edit=>"find_or_create", :sort=>[{:sort=>"author.name", :dir=>"ASC"},{:sort=>"title", :dir=>"DESC"}], :include=>[:author]) 
        }.should_not raise_error "Unknown key(s): on_edit"
      end
  end
end
