ActiveRecord::Schema.define :version => 0 do
  create_table "books", :force => true do |t|
    t.string   :title
    t.integer  :category_id
    t.integer  :author_id
    t.integer  :publisher_id
    t.integer  :parent_book_id
  end

  create_table "authors", :force => true do |t|
    t.string   :name
  end
  
  create_table "publishers", :force => true do |t|
    t.string   :name
  end
  
  create_table "keywords", :force => true do |t|
    t.string   :name
  end
  
  create_table "books_keywords", :id => false, :force => true do |t|
    t.integer  :book_id
    t.integer  :keyword_id
  end

  create_table "users", :force => true do |t|
    t.string   :name
    t.string   :address
  end
  
  create_table "loans", :force => true do |t|
    t.integer  :book_id
    t.integer  :user_id
    t.date :loan_date
    t.date :due_date
    t.boolean :is_returned
  end
  
  create_table "categories", :force => true do |t|
    t.string   :name
  end
end
