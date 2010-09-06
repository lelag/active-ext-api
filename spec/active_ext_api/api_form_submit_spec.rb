require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveExtAPI::ClassMethods, "ext_form_load" do
  before(:each) do
  
  end
  context " existing record form update (Ext Direct query)" do

    it "should update the record" do
      q = { :extTID => "7",
            :extAction => "Profile",
            :extMethod => "updateBasicInfo",
            :extType  => "rpc",
            :extUpload => "false",
            :id => "5",
            :title => "Book 5 Title"
            
      }
      r = Book.ext_form_submit(q) 
    end

  end
end
