#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#
#   TSファイルを 指定した秒数で分割する。
#
require 'optparse'
require 'fileutils'
require 'pp'
require 'benchmark'

$: << File.dirname( $0 )
require 'ffprob.rb'


$opt = {
  :t   => 1800,                 # 分割する秒数
  :n   => 1,                    # ナンバリングの開始番号
}


OptionParser.new do |opt|
  opt.on('-t n') { |v| $opt[:t] = v.to_i }
  opt.on('-n n') { |v| $opt[:n] = v.to_i }
  opt.parse!(ARGV)
end



#
#  実行時間表示付き system
#
def system2( bin, *cmd )

  printf("%s %s",bin,cmd.join(" ") )
  t = Benchmark.realtime { system(bin, *cmd ) }
  printf("%.2f Sec\n",t )
end


#
#   分割
#
def  split( input )

  ext = File.extname( input )
  output = File.basename( input,ext )
  output.sub!(/#\d+・ #\d+/,'')
  output.sub!(/\s+$/,'')
    
  r = ffprobe( input )
  dra = r[:duration2] 
  
  time = 0
  count = $opt[:n]
  while time < dra
    of = sprintf("%s #%02d%s",output,count,ext)
    cmd = %W( -ss #{time.to_s} -i )
    cmd << input
    cmd += %W( -t #{$opt[:t].to_s} -vcodec copy -acodec copy )
    cmd << of
    pp cmd.join(" ")
    if test( ?f, of )
      return raise
    end
    system2( "ffmpeg", *cmd )

    time += $opt[:t]
    count += 1
  end
end


ARGV.each do |ifn|
  split( ifn )
end
