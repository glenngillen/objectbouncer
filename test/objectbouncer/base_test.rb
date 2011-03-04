$:.unshift File.expand_path("..", File.dirname(__FILE__))
require "test_helper"

class SecretService
  include ObjectBouncer::Doorman
  door_policy do
    deny :shake_hands, :if => Proc.new{|person, president| person != president}
    allow :shake_hands, :if => Proc.new{|person, president| person.class == MichelleObama}
    deny :high_five, :unless => Proc.new{|person, president| person.who? == "it's me, Joe!"}
  end
end

class CoastGuard
  include ObjectBouncer::Doorman
  door_policy do
    lockdown # Overly protective are we?
    allow :watch_tv_appearance
  end
end

class President
  def shake_hands
    "shaking hands"
  end

  def high_five
    "high five!"
  end

  def watch_tv_appearance
    "I'm on your TV!"
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
      assert_raise ObjectBouncer::PermissionDenied do
        SecretService.as(joe_public).on(@president).shake_hands
      end
    end

    should "let the first lady get in close" do
      first_lady = MichelleObama.new
      assert_equal "shaking hands", SecretService.as(first_lady).on(@president).shake_hands
    end

    should "high five Biden" do
      vice_pres = JoeBiden.new
      assert_equal "high five!", SecretService.as(vice_pres).on(@president).high_five
    end

    should "not let the public high five" do
      joe_public = JoePublic.new
      assert_raise ObjectBouncer::PermissionDenied do
        SecretService.as(joe_public).on(@president).high_five
      end
    end

  end

  context "going into complete lockdown" do

    setup do
      @president = President.new
    end

    should "deny everything by default" do
      joe_public = JoePublic.new
      assert_raise ObjectBouncer::PermissionDenied do
        CoastGuard.as(joe_public).on(@president).high_five
      end
      assert_raise ObjectBouncer::PermissionDenied do
        CoastGuard.as(joe_public).on(@president).shake_hands
      end
    end

    should "allow if explictly said it's ok" do
      joe_public = JoePublic.new
      assert_equal "I'm on your TV!", CoastGuard.as(joe_public).on(@president).watch_tv_appearance
    end
  end

  context "having a forgiving API" do

    setup do
      @president = President.new
    end

    should "let people chain methods either order" do
      joe_public = JoePublic.new
      assert_equal "I'm on your TV!", CoastGuard.as(joe_public).on(@president).watch_tv_appearance
      assert_equal "I'm on your TV!", CoastGuard.on(@president).as(joe_public).watch_tv_appearance
    end
  end
end
