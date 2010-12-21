# encoding: utf-8

# Original source is "青空文庫→TeX（ver. 0.9.5 2004/5/5 psitau）"
# see: http://psitau.kitunebi.com/aozora.html
#
# Also another source is "青空キンドル [Beta]"
# see: http://a2k.aill.org/

require 'nkf'

class Aozora4Reader

  PreambleLineNumber=13
  KANJIPAT = "[々〇〻\u3400-\u9FFF\uF900-\uFAFF※ヶ]"

  def self.a4r(file)
    self.new(file).main
  end

  def initialize(file)
    @inputfile_name = file

    @jisage = false
    @log_text = []
    @line_num=0
    @gaiji = {}
    @gaiji2 = {}
  end

  # UTF-8で出力
  def normalize(l)
    ##l.gsub!(/&/, '\\\\&')
    l.to_s
  end
  
  # 全角→半角
  def to_single_byte(str)
    s = str.dup
    if s =~ /[０-９]/
      s.tr!("１２３４５６７８９０", "1234567890")
    elsif s =~ /[一二三四五六七八九〇]/
      s.tr!("一二三四五六七八九〇", "1234567890")
    end
    case s
    when /\d十\d/
      s.sub!(/(\d)十(\d)/, '\1\2')
    when /\d十/
      s.sub!(/(\d)十/, '\{1}0')
    when /十\d/
      s.sub!(/十(\d)/, '1\1')
    when /十/
      s.sub!(/十/, "10")
    end
    if s =~/[！？]/
      s.tr!("！？", "!?")
    end

    return s
  end
  

  # プリアンブルの出力
  def preamble
    str = <<"END_OF_PRE"
\\documentclass[a5paper]{tbook}
%\\documentclass[a5paper, twocolumn]{tbook}
%\\usepackage[deluxe]{otf}
\\usepackage[expert, deluxe]{otf}
%\\usepackage{utf}
\\usepackage{furikana}
\\usepackage{type1cm}
\\usepackage[size=large]{aozora4reader}
\\def\\rubykatuji{\\rubyfamily\\tiny}
%\\def\\rubykatuji{\\tiny}%for UTF package
%\\renewenvironment{teihon}{\\comment}{\\endcomment}
\\usepackage[dvipdfm,bookmarks=false,bookmarksnumbered=false,hyperfootnotes=false,%
            pdftitle={#{@title}},%
            pdfauthor={#{@author}}]{hyperref}
%% Bookmarkの文字化け対策（日本語向け）
\\ifnum 46273=\\euc"B4C1 % 46273 == 0xB4C1 == 漢(EUC-JP)
  \\AtBeginDvi{\\special{pdf:tounicode EUC-UCS2}}%
\\else
  \\AtBeginDvi{\\special{pdf:tounicode 90ms-RKSJ-UCS2}}%
\\fi

END_OF_PRE

    str
  end

  # 底本の表示用
  def postamble
    str = <<"END_OF_POST"
\\theendnotes
\\begin{teihon}
\\clearpage\\null\\newpage\\thispagestyle{empty}
\\begin{minipage}<y>{\\textheight}
\\vspace{1\\baselineskip}
\\scriptsize
END_OF_POST

    str
  end

  # アクセントの処理用
  # http://www.aozora.gr.jp/accent_separation.html
  # http://cosmoshouse.com/tools/acc-conv-j.htm
  def translate_accent(l)
    l.gsub!(/([ij]):/){"\\\"{\\#{$1}}"}
    l.gsub!(/([AIOEUaioeu])(['`~^])/){"\\#$2{#$1}"}
    l.gsub!(/([AIOEUaioeu]):/){"\\\"{#$1}"}
    l.gsub!(/([AIOEUaioeu])_/){"\\={#$1}"}
    l.gsub!(/([!?])@/){"#$1'"}
    l.gsub!(/([Aa])&/){"\\r{#$1}"}
    l.gsub!(/AE&/){"\\AE"}
    l.gsub!(/ae&/){"\\ae"}
    l.gsub!(/OE&/){"\\OE"}
    l.gsub!(/oe&/){"\\oe"}
    l.gsub!(/s&/){"\\ss"}
    l.gsub!(/([cC]),/){"\\c{#$1}"}
    l.gsub!(/〔/,'')
    l.gsub!(/〕/,'')
    return l
  end


  # 外字の処理用
  def translate_gaiji(l)
    if l =~/※［＃([^］]*)、([^、］]*)］/
      if @gaiji2[$1]
        l.gsub!(/※［＃([^］]*)、([^、］]*)］/){@gaiji2[$1]}
      end
    end
    ## ※［＃「姉」の正字、「女＋※［＃第3水準1-85-57］のつくり」、256-下-16］
    if l =~/※［＃([^］]*※［＃[^］]*］[^］]*)、([^、］]*)］/
      if @gaiji2[$1]
        l.gsub!(/※［＃([^］]*※［＃[^］]*］[^］]*)、([^、］]*)］/){@gaiji2[$1]}
      end
    end
    if l =~ /※［＃[^］]*?※［＃[^］]*?[12]\-\d{1,2}\-\d{1,2}[^］]*?］[^］]*?］/
      l.gsub!(/※［＃([^］]*?)※［＃([^］]*?([12]\-\d{1,2}\-\d{1,2})[^］]*?)］([^］]*?)］/){"※\\footnote{#$1"+@gaiji[$3]+"#$4}"}
    end
    if l =~ /※［＃[^］]*?[12]\-\d{1,2}\-\d{1,2}[^］]*?］/
      l.gsub!(/※［＃([^］]*?([12]\-\d{1,2}\-\d{1,2})[^］]*?)］/){@gaiji[$2]}
    end
    if l =~ /※［＃感嘆符三つ.*］/
      l.gsub!(/※［＃感嘆符三つ.*?］/){ "\\rensuji{!!!}"}
    end
    if l =~ /※［＃[^］]+?］/
      l.gsub!(/※［＃([^］]+?)］/, '※\\footnote{\1}')
    end

    if l =~ /※/
      STDERR.puts("Remaining Unprocessed Gaiji Character in Line #@line_num.")
      @log_text << normalize("未処理の外字が#{@line_num}行目にあります．\n")
    end
    return l
  end

  # ルビの処理用
  def translate_ruby(l)

    # 被ルビ文字列内に外字の注記があるばあい，ルビ文字列の後ろに移動する
    # ただし，順番が入れ替わってしまう
    while l =~ /※\\footnote\{[^(?:\\footnote)]+\}(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))*?《.+?》/
      l.sub!(/(※)(\\footnote\{[^(?:\\footnote)]+\})((?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))*?《.+?》)/, '\1\3\2')
    end

    # 被ルビ文字列内に誤記などの注記が存在する場合は、ルビの後ろに移動する
    while l =~ /(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?［＃[^］]*?］(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))*?《.+?》/
      l.sub!(/((?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?)(［＃[^］]*?］)((?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))*?《.+?》)/, '\1\3\2')
    end

    # ルビ文字列内に誤記などの注記が存在する場合は、ルビの後ろに移動する
    if l =~ /《[^》]*?［＃[^］]*?］[^》]*?》/
      l.gsub!(/(《[^》]*?)(［＃[^］]*?］)([^》]*?》)/, '\1\3\2')
    end

    # 一連のルビの処理
    # １ 縦棒ありの場合
    if l =~ /｜/
      l.gsub!(/｜(.+?)《(.+?)》/, '\\ruby{\1}{\2}')
    end

    # ２ 漢字および外字
    if l =~ /(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?《.+?》/
      l.gsub!(/((?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?)《(.+?)》/, '\\ruby{\1}{\2}')
    end

    # ３ ひらがな
    if l =~ /[あ-ん](?:[ぁ-んーヽヾ]|\\CID\{12107\})*?《.+?》/
      l.gsub!(/([あ-ん](?:[ぁ-んーヽヾ]|\\CID\{12107\})*?)《(.+?)》/, '\\ruby{\1}{\2}')
    end

    # ４ カタカナ
    if l =~ /[ア-ヴ](?:[ァ-ヴーゝゞ]|\\CID\{12107\})*?《.+?》/
      l.gsub!(/([ア-ヴ](?:[ァ-ヴーゝゞ]|\\CID\{12107\})*?)《(.+?)》/, '\\ruby{\1}{\2}')
    end

    # ５ 全角アルファベットなど
    if l =~ /[Ａ-Ｚａ-ｚΑ-Ωα-ωА-Яа-я・]+?《.+?》/
      l.gsub!(/([Ａ-Ｚａ-ｚΑ-Ωα-ωА-Яа-я・]+?)《(.+?)》/, '\\ruby{\1}{\2}')
    end

    # ６ 半角英数字
    if l =~ /[A-Za-z0-9#\-\;\&.\'\^\` ]+?《.+?》/
      l.gsub!(/([A-Za-z0-9#\-\;\&. ]+?)《(.+?)》/, '\\ruby{\1}{\2}')
    end
    if l =~ /《.*?》/
      STDERR.puts("Unknown ruby pattern found in #@line_num.")
      @log_text << normalize("未処理のルビが#{@line_num}行目にあります．\n")
    end

    return l
  end

  # 傍点の処理用
  def translate_bouten(l)
    if l =~ /［＃「.+?」に傍点］/
      l.gsub!(/(.+?)［＃.*?「\1」に傍点］/, '\\bou{\1}')
    end
    if l =~ /［＃「.+?」に白ゴマ傍点］/
      l.gsub!(/(.+?)［＃.*?「\1」に白ゴマ傍点］/, '\\sirogomabou{\1}')
    end
    if l =~ /［＃「.+?」に丸傍点］/
      l.gsub!(/(.+?)［＃.*?「\1」に丸傍点］/, '\\marubou{\1}')
    end
    if l =~ /［＃「.+?」に白丸傍点］/
      l.gsub!(/(.+?)［＃.*?「\1」に白丸傍点］/, '\\siromarubou{\1}')
    end
    if l =~ /［＃「.+?」に黒三角傍点］/
      l.gsub!(/(.+?)［＃.*?「\1」に黒三角傍点］/, '\\kurosankakubou{\1}')
    end
    if l =~ /［＃「.+?」に白三角傍点］/
      l.gsub!(/(.+?)［＃.*?「\1」に白三角傍点］/, '\\sirosankakubou{\1}')
    end
    if l =~ /［＃「.+?」に二重丸傍点］/
      l.gsub!(/(.+?)［＃.*?「\1」に二重丸傍点］/, '\\nijyuumarubou{\1}')
    end
    if l =~ /［＃「.+?」に蛇の目傍点］/
      l.gsub!(/(.+?)［＃.*?「\1」に蛇の目傍点］/, '\\jyanomebou{\1}')
    end
    return l
  end

  # 傍線の処理用
  def translate_bousen(l)
    if l =~ /［＃「.+?」に傍線］/
      l.gsub!(/(.+?)［＃「\1」に傍線］/, '\\bousen{\1}')
    end
    if l =~ /［＃「.+?」に二重傍線］/
      l.gsub!(/(.+?)［＃「\1」に二重傍線］/, '\\bousen{\1}')
    end
    if l =~ /［＃「.+?」に鎖線］/
      l.gsub!(/(.+?)［＃「\1」に鎖線］/, '\\bousen{\1}')
    end
    if l =~ /［＃「.+?」に破線］/
      l.gsub!(/(.+?)［＃「\1」に破線］/, '\\bousen{\1}')
    end
    if l =~ /［＃「.+?」に波線］/
      l.gsub!(/(.+?)［＃「\1」に波線］/, '\\bousen{\1}')
    end
    return l
  end

  # ルビの調整
  def tuning_ruby(l)

    # １ 直前が漢字の場合
    if l =~ /(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))\\ruby/
      l.gsub!(/((?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\})))\\ruby/, '\1\\Ruby')
    end

    # ２ 直後が漢字の場合
    if l =~ /\\ruby\{(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}\{(?:[^\\\{\}]|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))/
      l.gsub!(/\\ruby(\{(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}\{(?:[^\\\{\}]|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\})))/, '\\Ruby\1')
    end

    # ３ ルビが連続する場合
    while l =~ /\\(?:ruby|RUBY|Ruby)\{(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}\{(?:[^\\{}]|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}\\ruby/
      l.sub!(/\\(?:ruby|RUBY|Ruby)(\{(?:#{KANJIPAT}|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\}\{(?:[^\\{}]|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?\})\\ruby/, '\\RUBY\1\\RUBY')
    end
  end

  # 傍点の調整
  def tuning_bou(l)
    # 傍点の中の「くの字点」を変換
    while l =~ /(\\[a-z]*?bou\{(?:\w|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?)(\\ajD?Kunoji)\{\}((?:\w|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))*?)\}/
      l.gsub!(/((\\([a-z]*?)bou)\{(?:\w|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))+?)(\\ajD?Kunoji)\{\}((?:\w|(?:\\UTF\{[0-9a-fA-F]+\}|\\CID\{[0-9]+\}))*?)\}/, '\1}\4with\3Bou\2{\5}')
    end
    if l =~ /\\[a-z]*?bou\{\}/
      l.gsub!(/\\([a-z]*?)bou\{\}/, '{}')
    end
    return l
  end

  # 外字用ハッシュを作成
  def load_gaiji
    datadir = File.dirname(__FILE__)+"/../data"
    File.open(datadir+"/gaiji.txt") do |f|
      while gaiji_line = f.gets
        gaiji_line.chomp!
        key, data = gaiji_line.split
        @gaiji[key] = data
      end
    end

    File.open(datadir+"/gaiji2.txt") do |f|
      while gaiji_line = f.gets
        gaiji_line.chomp!
        key, data = gaiji_line.split
        data.gsub(/#.*$/,'')
        @gaiji2[key] = data
      end
    end

  end

  # 
  # メインパート
  # 
  def main
    load_gaiji()

    # 入出力ファイルの定義
    outputfile_name = @inputfile_name.sub(/\.txt$/, ".tex")
    inputfile = File.open(@inputfile_name)
    outputfile = File.open(outputfile_name, "w")

    # プリアンブルの処理
    empty_line = 0
    in_note = false
    meta_data = []
    while empty_line < 2
      line = inputfile.gets.chomp
      line = NKF::nkf('-wS', line)
      if in_note
        if line =~ /^-+$/
          in_note = false
        end
      else
        if line =~ /^-+$/
          in_note = true
        else
          if line =~ /^$/
            empty_line += 1
          else
            if line =~ /《.*?》/
              translate_ruby(line)
            end
            meta_data << line
          end
        end
      end
    end

    @line_num +=  meta_data.size
    @title = normalize(meta_data.shift)
    case meta_data.size
    when 1
      @author = normalize(meta_data.shift)
    when 2
      @subtitle = normalize(meta_data.shift)
      @author = normalize(meta_data.shift)
    when 3
      @subtitle = normalize(meta_data.shift)
      @author = normalize(meta_data.shift)
      @subauthor = normalize(meta_data.shift)
    else
      @subtitle = normalize(meta_data.shift)
      @author = normalize(meta_data.shift)
      @subauthor = normalize(meta_data.shift)
      @meta_data = []
      until meta_data.empty?
        @metadata << normalize(meta_data.shift)
      end
    end

    outputfile.write(preamble())

    outputfile.print "\\title{"+@title+"}\n"
    outputfile.print "\\subtitle{"+@subtitle+"}\n" if @subtitle
    outputfile.print "\\author{"+@author+"}\n"
    outputfile.print "\\subauthor{"+@subauthor+"}\n" if @subauthor

    if @meta_data
      @meta_data.each do |data|
        outputfile.print "\\metadata{"+data+"}\n"
      end
    end
    outputfile.print "\\date{}\n"

    # 本文の処理
    outputfile.print "\\begin{document}\n\\maketitle\n"

    @line_num += PreambleLineNumber
    while line = inputfile.gets
      @line_num += 1
      line.chomp!
      line = NKF::nkf('-wS', line)

      break if line =~ /^底本/
      if line =~ /^　「/
        line.sub!(/^　「/, "\\mbox{　}\\kern0mm\\inhibitglue「")
      end
      if line =~ /[ワヰヱヲ]゛/
        line.gsub!(/ワ゛/, "\\ajLig{ワ゛}")
        line.gsub!(/ヰ゛/, "\\ajLig{ヰ゛}")
        line.gsub!(/ヱ゛/, "\\ajLig{ヱ゛}")
        line.gsub!(/ヲ゛/, "\\ajLig{ヲ゛}")
      end
      if line =~ /[？！]　/
        line.gsub!(/([？！])　/, '\1{}')
      end
      if line =~ /——/
        line.gsub!(/——/, "\\——{}")
      end
      if line =~ /／＼/
        line.gsub!(/／＼/, "\\ajKunoji{}")
      end
      if line =~ /／″＼/
        line.gsub!(/／″＼/, "\\ajDKunoji{}")
      end

=begin
	if line =~ /^　　+.+/
		line.gsub!(/^　　+([一二三四五六七八九〇十].*)/, '\\section*{\1}')
	end
=end

      while line =~ /(.+?)［＃(「\1」は横?[１|一]文字[^］]*?)］/
        line = line.sub(/(.+?)［＃(「\1」は横?[１|一]文字[^］]*?)］/){"\\ajLig{"+to_single_byte($1)+"}"}
      end
      if line =~ /［＃改丁.*?］/
        line.sub!(/［＃改丁.*?］/, "\\cleardoublepage")
      end
      if line =~ /［＃改[頁|ページ].*?］/
        line.sub!(/［＃改[頁|ページ].*?］/, "\\clearpage")
      end

      if line =~ /〔.*?〕/
        translate_accent(line)
      end

      if line =~ /※/
        translate_gaiji(line)
      end
      if line =~ /［＃(.+?)傍点］/
        translate_bouten(line)
      end
      if line =~ /《.*?》/
        translate_ruby(line)
      end
      if line =~ /［＃「(.+?)」に(?:二重)?[傍鎖破波]線］/
        translate_bousen(line)
      end
      if line =~ /［＃この行.*?([１２３４５６７８９０一二三四五六七八九〇十]*)字下げ］/
        outputfile.print "\\begin{jisage}{"+to_single_byte($1)+"}\n"
        line = line.sub(/［＃この行.*?字下げ］/, "")+"\n\\end{jisage}"
        @line_num += 2
      end
      if line =~ /［＃.*?字下げ.*?(?:終わり|まで).*?］/ 
        line = line.sub(/［＃.*?字下げ.*?(?:終わり|まで).*?］/, "")+"\\end{jisage}"
        @jisage = false
      end
      if line =~ /［＃ここから.+字下げ.*?］/
        if @jisage
          outputfile.print "\\end{jisage}\n"
          @line_num += 1
        end
        line.sub!(/［＃ここから.*?([１２３４５６７８９０一二三四五六七八九〇十]*)字下げ.*?］/){"\\begin{jisage}{"+to_single_byte($1)+"}"}
        @jisage = true
      end
      if line =~ /［＃.*?地付き.*?］$/
        line = "\\begin{flushright}\n"+line.sub(/［＃.*?地付き.*?］$/, "\\end{flushright}")
        @line_num += 1
      elsif line =~ /［＃.*?地付き.*?］/
        line = line.sub(/［＃.*?地付き.*?］/, "\\begin{flushright}\n")+"\\end{flushright}"
        @line_num += 1
      end
      if line =~ /［＃.*?(?:行末|地)(?:から|より).*?([１２３４５６７８９０一二三四五六七八九〇十]*)字上.*?］$$/
        line = "\\begin{flushright}\\advance\\rightskip"+to_single_byte($1)+"zw\n"+line.sub(/［＃.*?(?:行末|地)(?:から|より).*?字上.*?］$/, "\\end{flushright}")
        @line_num += 1
      elsif line =~ /［＃.*?(?:行末|地)(?:から|より).*?([１２３４５６７８９０一二三四五六七八九〇十]*)字上.*?］/
        line = "\\begin{flushright}\\advance\\rightskip"+to_single_byte($1)+"zw\n"+line.sub(/［＃.*?(?:行末|地)(?:から|より)(.*?)字上.*?］/,"")+"\\end{flushright}"
        @line_num += 1
      end
      if line =~ /［＃「.+?」は返り点］/
        line.gsub!(/(.+)［＃「\1」は返り点］/, '\\kaeriten{\ajKunten{\1}}')
      end
      if line =~ /［＃[一二上中下甲乙丙丁レ]*］/
        line.gsub!(/［＃([一二上中下甲乙丙丁レ]*)］/, '\\kaeriten{\ajKunten{\1}}')
      end
      if line =~ /［＃（.*?）］/
        line.gsub!(/［＃（(.*?)）］/, '\\okurigana{\1}')
      end
      if line =~ /［＃「.+?」.*?ママ.*?注記］/
        line.gsub!(/(.+)［＃「\1」.*?ママ.*?注記］/, '\\ruby{\1}{ママ}')
      end

      if line =~ /［＃[^］]+（([^）]+.png)）[^］]+］/
        line.gsub!(/［＃[^］]+（([^）]+.png)）[^］]+］/, '\\sashie{\1}')
      end

      if line =~ /［＃([１２３４５６７８９０一二三四五六七八九〇十]*)字下げ］/
        outputfile.print "\\begin{jisage}{"+to_single_byte($1)+"}\n"
        line = line.sub(/［＃.*?字下げ］/, "")+"\n\\end{jisage}"
      end

      if line =~ /［＃「(.*?)」は大見出し］/
        line.gsub!(/#{$1}［＃「(.*?)」は大見出し］/,"{\\Large #{$1}}")
      end
      if line =~ /［＃「(.*?)」は中見出し］/
        line.gsub!(/#{$1}［＃「(.*?)」は中見出し］/,"{\\large #{$1}}")
      end
      if line =~ /［＃「(.*?)」は太字］/
        line.gsub!(/(.+)［＃「\1」は太字］/,'{\\textbf{\1}}')
      end
      if line =~ /［＃「.+?」は縦中横］/
        line.gsub!(/(.+)［＃「\1」は縦中横］/, '\\rensuji{\1}')
      end
      if line =~ /［＃「.+?」は斜体］/
        line.gsub!(/(.+)［＃「\1」は斜体］/){
          shatai = to_single_byte($1).tr("ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ","abcdefghijklmnopqrstuvwxyz")
          "\\rensuji{\\textsl{"+shatai+"}}"
        }
      end
      line.tr!("┌┐┘└│─","┐┘└┌─│")
      if line =~ /［＃改段］/
        line.sub!(/［＃改段］/, "\\clearpage")
      end
      if line =~ /[aioeu]\^/i
        line.gsub!(/([aioeu])\^/i){ "\\\^{#{$1}}"}
      end
      if line =~ /[aioeu]\'/i
        line.gsub!(/([aioeu])\'/i){ "\\\'{#{$1}}"}
      end
      if line =~ /［＃天から.*?([１２３４５６７８９０一二三四五六七八九〇十]*)字下げ］/
        outputfile.print "\\begin{jisage}{"+to_single_byte($1)+"}\n"
        line = line.sub(/［＃天から.*?字下げ］/, "")+"\n\\end{jisage}"
      end

      line.gsub!(/［＃図形　□（四角）に内接する◆］/, '{\setlength{\fboxsep}{0pt}\fbox{◆}}')


      if line =~ /［＃[^］]+?］/
        line.gsub!(/［＃([^］]+?)］/, '\\endnote{\1}')
      end
      if line =~ /\\[a-z]*?bou/
        tuning_bou(line)
      end
      if line =~ /\\ajD?Kunoji\{\}\}/
        line.gsub!(/(\\ajD?Kunoji)\{\}\}/, '\1}')
      end
      if line =~ /\\ruby/
        tuning_ruby(line)
      end
      if line =~ /^$/
        line = "　"
      end
      outputfile.print normalize(line)+"\n"
    end

    # 底本の処理
    outputfile.write(postamble())
    outputfile.print normalize(line)+"\n"
    while line = inputfile.gets
      line.chomp!
      line = NKF::nkf('-wS', line)
      outputfile.print normalize(line)+"\n"
    end
    outputfile.print "\n\\end{minipage}\n\\end{teihon}\n\\end{document}\n"
    if @log_text.size > 0
      until @log_text.empty?
        outputfile.print @log_text.shift
      end
    end
  end
end
