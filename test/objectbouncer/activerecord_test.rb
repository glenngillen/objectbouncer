$:.unshift File.expand_path("..", File.dirname(__FILE__))
require "test_helper"
require "active_record"

class Book < ActiveRecord::Base
  establish_connection :adapter =>  "sqlite3",
                       :database => "objectbouncer_test.db"
  include ObjectBouncer::Doorman
  door_policy do
    deny :save,  :unless => Proc.new{|person| person.is_a?(Author) }
    deny :save!, :unless => Proc.new{|person| person.is_a?(Author) }
  end
end

class Author
end

class Reader
end

class ActiveRecordTest < Test::Unit::TestCase
  context "protecting the library" do

    setup do
      ObjectBouncer.unenforce!
      @author = Author.new
      @reader = Reader.new
    end

    should "not let a reader create a book" do
      assert_raise ObjectBouncer::PermissionDenied do
        Book.as(@reader).create!(:name => "Real Housewives of Orange County - The Musical")
      end
    end

    should "let an author create a book" do
      assert_nothing_raised do
        Book.as(@author).create!(:name => "Guns, Germs & Steel")
      end
    end

    should "default to existing ActiveRecord behaviour" do
      assert_nothing_raised do
        Book.create!(:name => "Freakanomics")
      end
    end

    should "provide means of enforcing a user" do
      ObjectBouncer.enforce!
      assert_raise ObjectBouncer::ArgumentError do
        Book.create!(:name => "Javascript: The Good Parts")
      end
      assert_nothing_raised do
        Book.as(@author).create!(:name => "Javascript: The Good Parts")
      end
    end

    context "with an existing book" do

      setup do
        @book = Book.create!(:name   => "On Food & Cooking",
                             :author => "Harold McGee",
                             :price  => 4900)
        @book_as_author = Book.as(@author).find(@book.id)
        @book_as_reader = Book.as(@author).find(@book.id)
      end

      should "prevent reading of individual attributes" do
      end

      should "prevent writing of individual attributes" do
      end

      should "pass user through associations" do
      end
    end
  end
end
