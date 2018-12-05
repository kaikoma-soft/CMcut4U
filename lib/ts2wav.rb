#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'benchmark'

require_relative 'common.rb'
require_relative 'FilePara.rb'
require_relative 'Ffmpeg.rb'


def ts2wav( fp )

  #
  #    wave 化
  #
  unless test( ?f, fp.wavfn )
    ffmpeg = Ffmpeg.new( fp.tsfn )
    errLog(sprintf("ts to wav %.2f Sec\n",Benchmark.realtime do
                     ffmpeg.ts2wav( outfn: fp.wavfn )
                   end))
  end

  return fp.wavfn
end


#
#
#
if File.basename($0) == "ts2wav.rb"
  $: << File.dirname( $0 )
  
  if ARGV.size > 0
    ts = ARGV[0]
  else
    ts = TestTS
  end
  fp = FilePara.new(ts)
    
  ts2wav( fp )
  
end
