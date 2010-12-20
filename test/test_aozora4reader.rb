# encoding: utf-8
require 'helper'

class TestAozora4reader < Test::Unit::TestCase
  def setup
    @a4r = Aozora4Reader.new("dummy")
  end

  context "accent" do
    should "suport \\ae" do
      l = "〔Quid aliud est mulier nisi amicitiae& inimica〕"
      l2 = 'Quid aliud est mulier nisi amiciti\\ae inimica'
      assert_equal l2, @a4r.translate_accent(l)
    end
    should "suport A:" do
      assert_equal '\\"{A}nderung', @a4r.translate_accent('A:nderung')
    end
    should "support U:" do
      assert_equal '\\"{U}bung', @a4r.translate_accent('U:bung')
    end
    should "support s&" do
      assert_equal 'tsch\\"{u}\\ss', @a4r.translate_accent('tschu:s&')
    end
    should "support a`" do
      assert_equal 'voil\\`{a}', @a4r.translate_accent('voila`')
    end
    should "support a^" do
      assert_equal '\\^{a}me', @a4r.translate_accent('a^me')
    end
    should "support c," do
      assert_equal 'fran\c{c}ais', @a4r.translate_accent('franc,ais')
    end
    should "support i'" do
      assert_equal 'Andaluc\\\'{i}a', @a4r.translate_accent('Andaluci\'a')
    end
    should "support i:" do
      assert_equal 'ha\\"{\\i}r', @a4r.translate_accent('hai:r')
    end
  end
end
