
class Category < ActiveRecord::Base
  has_many :books
end

class Keyword < ActiveRecord::Base
  has_and_belongs_to_many :books
end

class Book < ActiveRecord::Base
  belongs_to :author
  belongs_to :publisher
  has_and_belongs_to_many :keywords
  has_and_belongs_to_many :categories
  has_many :loans
  has_many :users, :through => :loans
  has_many :following_books, :class_name => "Book", :foreign_key => "parent_book_id"
  belongs_to :parent_book, :class_name => "Book"
end


class Author < ActiveRecord::Base
  has_many :books
  has_many :publishers, :through => :books
end


class Publisher < ActiveRecord::Base
  has_many :books
  has_many :authors, :through => :books
end

class User < ActiveRecord::Base
  has_many :loans
  has_many :books, :through => :loans
end

class Loan < ActiveRecord::Base
  belongs_to :user
  belongs_to :book
end

class FixtureLoader
  def self.init_table_users
    @user1 = User.new(:name => "Guillaume", :address => "1 rue de rivoli 75001 Paris")
    @user1.save
    @user2 = User.new(:name => "Yuriko", :address => "1 rue de rivoli 75001 Paris")
    @user2.save
    @user3 = User.new(:name => "Albert", :address => "5 rue des boulets 75001 Paris")
    @user3.save
  end

  def self.init_table_publishers
    @publisher1 = Publisher.new(:name => "Addison Wesley") 
    @publisher1.save
    @publisher2 = Publisher.new(:name => "McGrow Hill") 
    @publisher2.save
    @publisher3 = Publisher.new(:name => "Lune d'encre Denoel") 
    @publisher3.save
  end

  def self.init_table_authors
    @author1 = Author.new(:name => "Bjarne Stoustrup")
    @author1.save
    @author2 = Author.new(:name => "JM Rifflet")
    @author2.save
    @author3 = Author.new(:name => "Douglas Adams")
    @author3.save
    @author4 = Author.new(:name => "George Orwell")
    @author4.save
    @author5 = Author.new(:name => "Ray Bradburry")
    @author5.save
    @author6 = Author.new(:name => "Aldous Huxley")
    @author6.save
    @author7 = Author.new(:name => "Hakon Wium Lie")
    @author7.save
  end

  def self.init_table_keywords
    @kw1 = Keyword.new(:name => "Programming")
    @kw2 = Keyword.new(:name => "Meaning of life")
    @kw3 = Keyword.new(:name => "Towel")
    @kw4 = Keyword.new(:name => "Unix")
    @kw5 = Keyword.new(:name => "C++")
    @kw6 = Keyword.new(:name => "Must-read")
    @kw7 = Keyword.new(:name => "Hard to read")
    @kw8 = Keyword.new(:name => "Fiction")
    @kw1.save
    @kw2.save
    @kw3.save
    @kw4.save
    @kw5.save
    @kw6.save
    @kw7.save
    @kw8.save
  end

  def self.init_table_books
    @book1 = Book.new(:title => "La communication sous Unix")
    @book1.author = @author2
    @book1.publisher = @publisher2
    @book1.keywords << @kw1
    @book1.keywords << @kw4
    @book1.keywords << @kw6
    @book1.save
    @book2 = Book.new(:title => "Le guide du voyageur galactique")
    @book2.author = @author3
    @book2.publisher = @publisher3
    @book2.keywords << @kw2
    @book2.keywords << @kw6
    @book2.keywords << @kw8
    @book2.save
    @book3 = Book.new(:title => "Le dernier restaurant avant la fin du monde")
    @book3.author = @author3
    @book3.publisher = @publisher3
    @book3.keywords << @kw2
    @book3.keywords << @kw6
    @book3.keywords << @kw8
    @book3.parent_book = @book2
    @book3.save
    @book4 = Book.new(:title => "La vie, l'univers et le reste")
    @book4.author = @author3
    @book4.publisher = @publisher3
    @book4.keywords << @kw2
    @book4.keywords << @kw6
    @book4.keywords << @kw8
    @book4.parent_book = @book3
    @book4.save
    @book5 = Book.new(:title => "Le langage C++")
    @book5.author = @author1
    @book5.publisher = @publisher1
    @book5.keywords << @kw1
    @book5.keywords << @kw4
    @book5.keywords << @kw5
    @book5.save
  end

  def self.init_table_loans
    @loan1 = Loan.new(:loan_date => "2010-01-01", :due_date => "2010-01-14", :is_returned => true) 
    @loan1.book = @book5
    @loan1.user = @user1
    @loan1.save 
    @loan2 = Loan.new(:loan_date => "2010-02-01", :due_date => "2010-02-14", :is_returned => false) 
    @loan2.book = @book4
    @loan2.user = @user1
    @loan2.save 
    @loan3 = Loan.new(:loan_date => "2010-08-11", :due_date => "2010-08-24", :is_returned => false) 
    @loan3.book = @book1
    @loan3.user = @user2
    @loan3.save 
    @loan4 = Loan.new(:loan_date => "2010-01-01", :due_date => "2010-01-14", :is_returned => true) 
    @loan4.book = @book2
    @loan4.user = @user2
    @loan4.save 
  end

end
FixtureLoader.init_table_users
FixtureLoader.init_table_publishers
FixtureLoader.init_table_authors
FixtureLoader.init_table_keywords
FixtureLoader.init_table_books
FixtureLoader.init_table_loans
  
