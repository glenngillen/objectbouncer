$:.unshift File.expand_path("..", File.dirname(__FILE__))
require "test_helper"

class SecretService
  include ObjectBouncer::Doorman
  door_policy do
    deny :shake_hands, :if => Proc.new{|person, president| person != president}
    allow :shake_hands, :if => Proc.new{|person, president| person.class == MichelleObama}
    deny :high_five, :unless => Proc.new{|person, president| person.who? == "it's me, Joe!"}
    deny :give, :unless => Proc.new{|person, president, *args| args.first == :campaign_donation }
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
      secret_service = SecretService.new(joe_public, @president)
      assert_raise ObjectBouncer::PermissionDenied do
        secret_service.shake_hands
      end
    end

    should "let the first lady get in close" do
      first_lady = MichelleObama.new
      secret_service = SecretService.new(first_lady, @president)
      assert_equal "shaking hands", secret_service.shake_hands
    end

    should "high five Biden" do
      vice_pres = JoeBiden.new
      secret_service = SecretService.new(vice_pres, @president)
      assert_equal "high five!", secret_service.high_five
    end

    should "not let the public high five" do
      joe_public = JoePublic.new
      secret_service = SecretService.new(joe_public, @president)
      assert_raise ObjectBouncer::PermissionDenied do
        secret_service.high_five
      end
    end

    should "let the public give a donation" do
      joe_public = JoePublic.new
      secret_service = SecretService.new(joe_public, @president)
      assert_equal "thanks", secret_service.give(:campaign_donation)
    end

    should "not let the public give a package" do
      joe_public = JoePublic.new
      secret_service = SecretService.new(joe_public, @president)
      assert_raise ObjectBouncer::PermissionDenied do
        secret_service.give(:suspect_package)
      end
    end

  end

  context "going into complete lockdown" do

    setup do
      @president = President.new
    end

    should "deny everything by default" do
      joe_public = JoePublic.new
      coast_guard = CoastGuard.new(joe_public, @president)
      assert_raise ObjectBouncer::PermissionDenied do
        coast_guard.high_five
      end
      assert_raise ObjectBouncer::PermissionDenied do
        coast_guard.shake_hands
      end
    end

    should "allow if explictly said it's ok" do
      joe_public = JoePublic.new
      coast_guard = CoastGuard.new(joe_public, @president)
      assert_equal "I'm on your TV!", coast_guard.watch_tv_appearance
    end
  end

end
