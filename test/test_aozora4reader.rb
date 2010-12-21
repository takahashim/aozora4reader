# encoding: utf-8
require 'helper'

class TestAozora4reader < Test::Unit::TestCase
  def setup
    @a4r = Aozora4Reader.new("dummy")
    @a4r.load_gaiji
  end

  context "accent" do
    should "support \\ae" do
      l = "〔Quid aliud est mulier nisi amicitiae& inimica〕"
      l2 = 'Quid aliud est mulier nisi amiciti\\ae inimica'
      assert_equal l2, @a4r.translate_accent(l)
    end
    should "support A:" do
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

  context "gaiji" do
    should "support 磽※［＃「石＋角」、第3水準1-89-6］" do
      l = "磽※［＃「石＋角」、第3水準1-89-6］"
      l2 = '磽\\UTF{786e}'
      assert_equal l2, @a4r.translate_gaiji(l)
    end
=begin
    should "support 因※［＃「木＋于」、10-7］" do
      l = "因※［＃「木＋于」、10-7］"
      l2 = '因\\UTF{6745}'
      assert_equal l2, @a4r.translate_gaiji(l)
    end

    should "support 於※［＃「革＋干」、49-11］王" do
      l = "於※［＃「革＋干」、49-11］王"
      l2 = '於\\UTF{976C}王'
      assert_equal l2, @a4r.translate_gaiji(l)
    end
=end

    should "support complex" do
      l = "とくは※［＃「姉」の正字、「女＋※［＃第3水準1-85-57］のつくり」、256-下-16］や兄が順序に呼ばれたので、こんどは自分が呼ばれたのだと氣が附いた。そして只目を※［＃「目＋爭」、第3水準1-88-85］つて役人の顏を仰ぎ見た。"
      l2 = 'とくは\\UTF{59ca}や兄が順序に呼ばれたので、こんどは自分が呼ばれたのだと氣が附いた。そして只目を\\UTF{775c}つて役人の顏を仰ぎ見た。'
      assert_equal l2, @a4r.translate_gaiji(l)
    end



  end
end
