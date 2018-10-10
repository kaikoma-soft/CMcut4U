#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#

#
#   コンテナを変換する。(中身はそのまま)
#
require 'optparse'
Version = "1.0.0"
  
def usage()
  pname = File.basename($0)
    usageStr = <<"EOM"
Usage: #{pname} [Options]...  ts-file

  Options:
  --ts        mpeg-TS コンテナに変換
  --ps        mpeg-PS コンテナに変換
  --mp4       mp4 コンテナに変換
  --link      元ファイルをリネームして、変換後ファイルへの link を作成
  --help      Show this help

#{pname} ver #{Version}
EOM
    print usageStr
    exit 1
end

$opt = {
  :cont => :ts,
  :link => false,
}

OptionParser.new do |opt|
  opt.on('--ts')  { $opt[:cont] = :ts }
  opt.on('--ps')  { $opt[:cont] = :ps }
  opt.on('--mp4') { $opt[:cont] = :mp4  }
  opt.on('--link'){ $opt[:link] = true  }
  opt.on('--help') { usage() }
  opt.parse!(ARGV)
end

case $opt[:cont]
when :mp4
  ext = ".mp4"
  f   = "mp4"
when :ps
  ext = ".ps"
  f   = "dvd"
when :ts
  ext = ".ts2"
  f   = "mpegts"
else
  usage()
end

iname = ARGV[0]
if test( ?f, iname )
  if iname =~ /\.ts$/
    oname = iname.sub(/\.ts/, ext )
    arg = %W( ffmpeg -y -analyzeduration 100M -probesize 100M -i )
    arg << iname
    arg += %w( -map 0:0 -map 0:1 )
    arg += %W( -c:v copy -c:a copy -f #{f} )
    arg << oname
    #p arg
    system( *arg )

    if test( ?f, oname ) and $opt[:link] == true
      org = iname + ".org"
      File.rename(iname, org )
      File.symlink( oname, iname )
    end
  end
end
