# -*- coding: utf-8 -*-

# mikutterm
#   by syusui_s

require 'readline'

module Radix62
  BASE = 62
  DIGITCHARS = ('0'..'9').first(10) + ('a'..'z').first(26) + ('A'..'Z').first(26)

  module_function

  def conv(num)
    return nil if not num.kind_of?(Integer)

    digits = []
    until num.zero?
      digits.push(num % BASE)
      num = (num / BASE).to_i
    end
    digits.reverse end

  def unconv(str)
    return nil if str.class != String
    digbase = 1;rtn = 0
    str.split("").map{|val| (t = DIGITCHARS.index(val)).nil? ? (return nil) : t}.reverse.each{|t| rtn+=digbase*t;digbase*=BASE}
    rtn end

  def conv_show(num)
    return nil if num.nil?
    rtn = Array::new
    conv(num).each{|t| rtn.push(DIGITCHARS[t])}
    rtn end

  def to_show(num)
    return nil if num.nil?
    rtn = ""
    conv_show(num).each{|t| rtn += t}
    rtn end
end

Plugin::create :mikutterm do
  PROMPT = Environment::NAME
  UNESCAPE_RULE={'&amp;' => '&' ,'&gt;' => '>', '&lt;' => '<'}.freeze
  COLORS = {
    'bold'      => '1',
    'underscore'=> '4',
    'black'     => '30',
    'red'       => '31',
    'green'     => '32',
    'yellow'    => '33',
    'blue'      => '34',
    'magenta'   => '35',
    'cyan'      => '36',
    'white'     => '37',
    'bg_black'  => '40',
    'bg_red'    => '41',
    'bg_green'  => '42',
    'bg_yellow' => '43',
    'bg_blue'   => '44',
    'bg_magenta'=> '45',
    'bg_cyan'   => '46',
    'bg_white'  => '47'
  }.freeze

  CLR_INPUT    = ["white","bg_green","bold"]

  CLR_TIME     = ["bold","black"]
  CLR_USERNAME = ["yellow"]
  CLR_USERID   = ["cyan"]
  CLR_SOURCE   = ["black","bold"]
  CLR_STATUSID = ["green"]

  CLR_FROMME   = ["bg_yellow"]  
  CLR_SYSTEM   = ["bold","magenta"]
  CLR_RETWEET  = ["bold","blue"]
  CLR_FAVORITE = ["bold","yellow"]

  CLR_ATTWEET  = ["bold","red"]
  CLR_HASHTAG  = ["magenta"]
  CLR_ATUSER   = ["red"]
  CLR_URL      = ["blue"]
  CLR_QT_RT    = ["bold","blue"]

  def unescape(text)
    text.gsub(/(&amp;|&gt;|&lt;)/){|m| UNESCAPE_RULE[m]} end

  def coloring(text, *a_colors)
    "\e[" + a_colors.map!{|s| COLORS.key?(s) ? COLORS[s] : s }.join(";") + "m#{text}\e[0m" end

  def formattime(time)
    time.strftime("%Y%m%d") == Time.now.strftime("%Y%m%d") ? time.strftime("%H:%M:%S") : time.strftime("%y/%m/%d %H:%M:%S") end

  def msgtypeclr(m)
    rtn = ""
    if m.from_me? then
      rtn+= " #{coloring("(Me)", *CLR_FROMME)}"
    elsif m.system? then
      rtn+= " #{coloring("(Sys)", *CLR_SYSTEM)}"
    elsif m.retweet? then
      rtn+= " #{coloring("(RT)", *CLR_RETWEET)}"
    elsif m.favorite? then
      rtn+= " #{coloring("(★)", *CLR_FAVORITE)}"
    elsif m.to_me? then 
      rtn+= " #{coloring("(Reply)", *CLR_ATTWEET)}" 
    end
    rtn end

  def formatmsgshow(m)
    m.retweet? ? m.to_show.sub(/RT\s/,"") : m.to_show end

  def msgcoloring(text)
    text.gsub(/#\S+/){|item|
      coloring(item, *CLR_HASHTAG) # ハッシュタグの色
    }.gsub(/@[\w\_]+[^\W]+/){|item|
      coloring(item, *CLR_ATUSER) # @USERNAMEの色
    }.gsub(/http:\/\/\S+/){|item|
      item = MessageConverters.expand_url([item])[item] # t.coを展開
      coloring(item, *CLR_URL) # URLの色
    }.gsub(/https:\/\/\S+/){|item|
      item = MessageConverters.expand_url([item])[item] # t.coを展開
      coloring(item, *CLR_URL) # URLの色
    }.gsub(/\s+RT\s+/){|item|
      coloring(item, *CLR_QT_RT) # RTの色
    }.gsub(/\s+QT\s+/){|item|
      coloring(item, *CLR_QT_RT) # QTの色
    }
    end

  def sysbot(text)
    puts ""
    puts "#{coloring("("+formattime(Time.now)+")", *CLR_TIME)} #{coloring("mikutter_bot", *CLR_USERID)} #{coloring("(Sys)", *CLR_SYSTEM)} #{msgcoloring(text)}"
  end

  def mikuexit
    sysbot("終了します。");Delayer.new{exit} end

  def putshelp
    puts "---- commands ----"
    puts "  post/p/t MSG\t\tMSGをツイートします"
    puts "  r/reply SID MSG\t\tステータスIDの表すツイート対するリプライを送信します"
    puts "  rt/retweet SID\tステータスIDの表すツイートをリツイートします"
    puts "  sleep TIME\t\tTIME秒間プロンプトを表示せずに待機します"
    puts "  sysbot MSG\t\tmikutter_botが呟いたように見えます"
    puts "  showurl SID\t\tステータスIDの表すツイートのURLを表示（\",\"で複数指定）"
    puts "  help\t\t\tこのメッセージを表示します。"
    puts "  exit/quit\t\tmikutterを終了します。"
  end

  def showtweet(m)
    usrid    = coloring("(@#{unescape(m.idname)})",*CLR_USERID)
    name     = coloring(unescape(m.user[:name]),*CLR_USERNAME)
    msg      = msgcoloring(formatmsgshow(m))
    src      = coloring("via "+m[:source], *CLR_SOURCE)
    statusid = coloring(Radix62::to_show(m[:id]), *CLR_STATUSID)
    time     = coloring("("+formattime(m[:created])+")", *CLR_TIME)

    puts  ""
    print "#{time} #{name} #{usrid}"
    puts  "#{msgtypeclr(m)} "
    puts  "#{msg} #{src} #{statusid}"
    print "-"*36
  end

  def showfaved(userby,msg)
    puts coloring("("+formattime(Time.now)+")", *CLR_TIME) + " " +
      coloring("★  " + (msg.from_me? ? "#{userby[:name]}（#{userby[:idname]}）さんが" : "") + "ツイートをお気に入り登録しました","bold","yellow")
    showtweet(msg)
  end
   
  def inputline(buf)
    # ツイートする 
    if buf =~ /^\s*(post|p|t)\s/ then
      post = buf.sub(/^\s*(post|p|t)\s/, "")
      if not post.gsub(/\s*/,"").empty? then
        Service.primary.post(:message => post)
        sysbot("post:ツイートしました！")
      else sysbot("文字列が空です") end
    # リプライ
    elsif buf =~ /^\s*(r|reply)\s/ then
      rdxmsgid, post = buf.sub(/^\s*(r|reply)\s/, "").split(" ", 2)
      if not post.gsub(/\s*/,"").empty? then
        m = Message.findbyid(Radix62::unconv(rdxmsgid))
        if m
          m.post(:message => "@#{m.idname} #{post}")
          sysbot("reply:返信しました！")
        else sysbot("reply:指定されたツイートは存在しません") end
      else sysbot("reply:文字列が空です") end
    # リツイート
    elsif buf =~ /^\s*(rt|retweet)\s/ then
      rdxmsgid = buf.sub(/^\s*(rt|retweet)\s/, "").split(" ", 2)[0]
      if not rdxmsgid.empty? then
        m = Message.findbyid(Radix62::unconv(rdxmsgid))
        if m and m.retweetable? and (not m.retweeted?)
          m.retweet
          sysbot("retweet:リツイートしました！")
        else sysbot("retweet:リツイートできませんでした") end
      else sysbot("retweet:IDを指定してください") end
    # 終了する
    elsif buf =~ /^\s*(ex|qu)it/ then
      mikuexit
    # 読込待機時間を設定
    elsif buf =~ /^\s*sleep\s+/ then
      if buf =~ /^\s*sleep\s+(?!\d*\D+)\d+/ then
        sleeptime = buf.sub(/^\s*sleep\s*/,"").to_i
        sysbot("sleep:#{sleeptime}秒間プロンプトを表示せずにタイムライン更新を待機します。")
      else sysbot("sleep:不正な入力値です。整数値で秒数を指定してください。") end
    # mikutter_botにつぶやかせるように見せかける
    elsif buf =~ /^\s*sysbot\s+/ then
      sysbot(buf.sub(/^\s*sysbot\s+/,""))
    # ステータスURLを表示する
    elsif buf =~ /^\s*showurl\s+/ then
      buf.sub(/^\s*showurl\s*/,"").gsub(/\s/,"").split(",").each{|t|
        sysbot("#{t} --> https://twitter.com/mikutter_bot/status/#{Radix62.unconv(t).to_s}")
      }
    # ヘルプを表示
    elsif buf =~ /^\s*help/ then
      sleeptime = 0
      putshelp
    # 何もないときは何もしない
    elsif buf.gsub(/\s/,"")  == "" then
    # 未定義のコマンド
    else sysbot("\"#{buf}\"というコマンドはありません。ヘルプを見るには、helpと入力してください。") end
  end

  # 表示処理
  on_update do |service, messages|
    messages = messages.sort_by{|item| item[:created]}
    messages.each{|m| showtweet(m) }
  end

  on_favorite do |service, userby, msg|
    showfaved(userby,msg)
  end

  Thread.new do
    loop do
      buf = Readline.readline(coloring("#{PROMPT}>", *CLR_INPUT)+" ").gsub(/[\t\n\r\f]/, "")
      inputline(buf)
    end
  end
end
