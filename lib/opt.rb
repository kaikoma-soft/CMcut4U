#!/usr/bin/ruby 
# -*- coding: utf-8 -*-
#
#  option の処理
#
#
require 'optparse'

$opt = {
  :v         => false,          # verbose
  :d         => false,          # debug
  :D         => false,          # more debug
  :f         => false,          # force exec
  :uc        => false,          # use cache
  :cmsize    => false,          # force CM size
  :fade      => true,           # fade in out
  :calcOnly  => false,          # calc only( do not create mp4 )
  :delLevel  => 0,              # delete level
  :ngOnly    => false,          # ng only convert mp4
  :limit     => nil,            # limit num
  :sa        => 3,              # 誤差の許容範囲
  :ic        => false,          # Ignore check chapList.txt
  :dir       => nil,            # subdir
}

def usage( type)
  pname = File.basename($0)

  if type == :single
    usageStr = "Usage: #{pname} [Options]...  TS_name\n"
  else
    usageStr = "Usage: #{pname} [Options]...\n"
  end
  usageStr += "\nOptions:\n"

  str = []
  if type == :all
    str << "-f          ロックファイルが存在していても実行する。"
  end

  if type == :all or type ==  :single
    str << "--co        CMカットに必要な計算のみ行う。mp4変換を行わない。"
    str << "--cm        本編画面サイズを $comSize にする。"
    str << "--dd n      最終・中間結果ファイルを削除する。"
    str << "--ic        chapList.txt のハッシュチェックを行わない。"
  end
  
  if type == :all or type == :chk
    str << "--ng        NG なものだけ対象にする。"
    str << "--dir name  処理対象のサブディレクトリの指定"
  end
  
  if type == :all or type == :single or type == :fix
    str << "--uc        中間結果ファイルを再利用する。"
  end

  str << "--sa n      誤差の許容範囲を n 秒にする。デフォルトは 3秒"
  str << "--help      Show this help"

  print usageStr
  str.each do |s|
    print "    " + s + "\n"
  end
  print "\n#{pname} ver #{Version}\n"
  exit 1
end

pname = File.basename($0)
type = nil
case pname
when "cmcuter.rb"    then type = :single
when "cmcuterAll.rb" then type = :all
when "cmcuterChk.rb" then type = :chk
when "fixGUI.rb"     then type = :fix
end

OptionParser.new do |opt|
  opt.on('-v')     { $opt[:v] = true }             # verbose
  opt.on('-d')     { $opt[:d] = true }             # debug
  opt.on('-D')     { $opt[:D] = true }             # debug2

  if type == :all
    opt.on('-f')     { $opt[:f] = true }             # 強制実行
  end

  if type == :all or type ==  :single
    opt.on('--co')   { $opt[:calcOnly] = true  }     # 
    opt.on('--cm')   { $opt[:cmsize] = true  }       # force CM size
    opt.on('--dd n') {|v| $opt[:delLevel] = v.to_i  }# delete data
    opt.on('--ic')   { $opt[:ic] = true  }           # ignore check
  end
  
  if type == :all or type ==  :chk
    opt.on('--ng')   { $opt[:ngOnly] = true  }
    opt.on('--dir name') {|v| $opt[:dir] = v  } 
  end
  
  if type == :all or type == :single or type == :fix
    opt.on('--uc')   { $opt[:uc] = true  }
  end

  opt.on('--sa n') {|v| $opt[:sa] = v.to_i }
  opt.on('--help') { usage( type ) }
  opt.parse!(ARGV)
end

