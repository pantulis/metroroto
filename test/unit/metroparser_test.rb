# -*- coding: utf-8 -*-
require 'test_helper'
require 'debugger'

class MetroparserTest < ActiveSupport::TestCase

  def prepare_tweet(str)
    twitt = Hash.new()
    twitt["text"]=str
    twitt["created_at"] = Time.now
    twitt["from_user"] = 1111
    twitt["id"] = rand(999999)+1
    
    twitt
  end

  def assert_valid_tweet(str)
    assert Metrotwitt.parse_twitt(prepare_tweet(str)), str
  end

  def assert_failed_tweet(str)
    assert !Metrotwitt.parse_twitt(prepare_tweet(str)), str
  end

  test "parse correct tweet" do
    debugger
    assert_valid_tweet('wadus #metroroto #l10 #tribunal cortada bla bla bla')
    assert_valid_tweet('wadus #metroroto #l1 #plaza-de-castilla patatin')
    assert_valid_tweet('wadus #metroroto #l1 #plaza-castilla patatin')
  end

  test "parse wrong tweet" do
    assert_failed_tweet ('impossible to parse')
  end

end
