#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'benchmark'

require_relative 'common.rb'
require_relative 'FilePara.rb'
require_relative 'Ffmpeg.rb'


def ts2png( fp )

  ffmpeg = Ffmpeg.new( fp.tsfn )
  info = ffmpeg.getTSinfo( )
  
  max = info[:duration2 ]
  h = info[:height].to_f
  w = info[:width].to_f

  unless test(?d, fp.picdir )
    FileUtils.mkpath( fp.picdir )
  end

  #
  #    screenshot
  #
  unless test(?d,fp.picdir)
    Dir.mkdir( fp.picdir )
  end

  #  0,0    w
  #   +-------+---+
  #   |TL     |TR |
  #   |       +---+ h
  #   |           |
  #   |BL      BR |
  #   +-----------+
  #
  
  w2 = (w * 0.18).round(2)
  h2 = (h * 0.2).round(2)
  case fp.position
  when "top-right"
    x2 = (w * 0.8).round(2)
    y2 = 0
  when "top-left"
    x2 = 0
    y2 = 0
  when "bottom-left"
    x2 = 0
    y2 = (h * 0.8).round(2)
  when "bottom-right"
    x2 = (w * 0.8).round(2)
    y2 = (h * 0.8).round(2)
  else         
    raise "position format error (#{fp.position})"
  end

  unless test( ?f, fp.picdir + "/ss_00001.jpg" )
    errLog(sprintf("ts to screenshot %.2f Sec\n", Benchmark.realtime do
                     ffmpeg.ts2ss( vf: (max * Fps).to_i,
                                   w:  w2,
                                   h:  h2,
                                   x2: x2,
                                   y2: y2,
                                   picdir: fp.picdir )
                   end))
  end
  
  return fp.picdir
end


#
#
#
if File.basename($0) == "ts2png.rb"
  $: << File.dirname( $0 )
  
  if ARGV.size > 0
    ts = ARGV[0]
  else
    ts = TestTS
  end
  fp = FilePara.new(ts)
    
  ts2png( fp )
  
end
