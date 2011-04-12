$:.unshift File.expand_path("..", File.dirname(__FILE__))
require "test_helper"

class President
  include ObjectBouncer::Doorman
  door_policy do
    deny :shake_hands, :unless => Proc.new{|person, president| person.is_a?(MichelleObama) }
    deny :shake_hands, :if => Proc.new{|person, president| person != president }
    deny :high_five, :unless => Proc.new{|person, president| person.who? == "it's me, Joe!"}
    deny :give, :unless => Proc.new{|person, president, *args| args.first == :campaign_donation }
  end

  def shake_hands
    "shaking hands"
  end

  def high_five
    "high five!"
  end

  def watch_tv_appearance
    "I'm on your TV!"
  end

  def give(gift)
    "thanks"
  end

end

class MichelleObama
end

class JoePublic
end

class JoeBiden
  def who?
    "it's me, Joe!"
  end
end

class ObjectBouncerTest < Test::Unit::TestCase
  context "keeping the president safe" do

    setup do
      @president = President.new
    end

    should "not let the public shake hands" do
      joe_public = JoePublic.new
      @president.current_user = joe_public
      assert_raise ObjectBouncer::PermissionDenied do
        @president.shake_hands
      end
    end

    should "let the first lady get in close" do
      first_lady = MichelleObama.new
      @president.current_user = first_lady
      assert_equal "shaking hands", @president.shake_hands
    end

    should "high five Biden" do
      vice_pres = JoeBiden.new
      @president.current_user = vice_pres
      assert_equal "high five!", @president.high_five
    end

    should "not let the public high five" do
      joe_public = JoePublic.new
      @president.current_user = joe_public
      assert_raise ObjectBouncer::PermissionDenied do
        @president.high_five
      end
    end

    should "let the public give a donation" do
      joe_public = JoePublic.new
      @president.current_user = joe_public
      assert_equal "thanks", @president.give(:campaign_donation)
    end

    should "not let the public give a package" do
      joe_public = JoePublic.new
      @president.current_user = joe_public
      assert_raise ObjectBouncer::PermissionDenied do
        @president.give(:suspect_package)
      end
    end

    should "be able to specify user on creation" do
      joe_public = JoePublic.new
      @president = President.as(joe_public).new
      assert_raise ObjectBouncer::PermissionDenied do
        @president.shake_hands
      end

      first_lady = MichelleObama.new
      @president = President.as(first_lady).new
      assert_equal "shaking hands", @president.shake_hands
    end

  end

end
