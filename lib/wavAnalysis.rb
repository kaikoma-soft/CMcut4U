#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pp'
require 'shellwords'
require 'benchmark'
require 'wav-file'

require_relative 'common.rb'
require_relative 'Silence.rb'

#
#   WAV を読んで、無音区間でチャプター分けをする。
#

def wavAnalysis1( wavfn )

  data = nil
  str = "wavAnalysis (%s) %.2f Sec\n"
  errLog(sprintf( str, wavfn,
                  Benchmark.realtime { data = wavAnalysis2( wavfn ) }
                ))
  data
end

def wavAnalysis2( wavfn )

  return nil unless test( ?f, wavfn )
  f = open(wavfn)
  format, chunks = WavFile::readAll(f)
  f.close

  #puts format.to_s

  dataChunk = nil
  chunks.each{|c|
    #puts "> #{c.name} #{c.size}"
    dataChunk = c if c.name == 'data' # find data chank
  }
  if dataChunk == nil
    puts 'no data chunk'
    exit 1
  end

  bit = 's*' if format.bitPerSample == 16 # int16_t
  bit = 'c*' if format.bitPerSample == 8  # signed char
  wavs = dataChunk.data.unpack(bit)       # read binary
  
  data = Silence.new
  f = 0
  zs = nil
  count = 1
  
  data.add( 0, 1 )              # start of data
  if format.channel == 1
    wavs.each do |i|
      if i < 3                 # 無音レベル
        if zs == nil
          zs = f
        end
      else
        if zs != nil
          if ( f - zs ) > ( WavRatio / 10 * 4 )   # 0.4 秒以上
            #printf("%3d %s - %s\n", count,f2min(zs,1),f2min(f,1))
            data.add( zs.to_f / WavRatio, f.to_f / WavRatio )
            count += 1
          end
          zs = nil
        end
      end
      f += 1
    end
  elsif format.channel == 2
    0.step(wavs.size-1,2 ) do |j|
      l = wavs[j]
      r = wavs[j+1]

      if l < 3 and r < 3   # 無音レベル
        if zs == nil
          zs = j
        end
      else
        if zs != nil
          if ( j - zs ) > ( WavRatio / 10 * 4 )    # 0.4 秒以上
            printf("%3d %s - %s\n", count,f2min(zs),f2min(j))
            count += 1
          end
        end
        zs = nil
      end
    end
  else
    raise
  end
  data.add( (f-1) / WavRatio, f / WavRatio ) # end of data

  
  data
end


#
#  frame から 0:00:00.00 形式に変換
#
def f2min( frame, ch = 2 )
  sec  = frame.to_f / WavRatio / ch
  h    = ( sec / 3600 ).to_i
  min  = ( ( sec - ( h * 3600))/ 60 ).to_i
  sec2 = sec % 60
  sprintf("%01d:%02d:%05.2f",h,min,sec2)
end


if File.basename($0) == "wavAnalysis.rb"
  $: << File.dirname( $0 )
  
  $opt = {
    :d => false,                # debug
  }

  OptionParser.new do |opt|
    opt.on('-d') { $opt[:d] = true }
    opt.parse!(ARGV)
  end

  wavfn = ARGV.shift if ARGV.size > 0
  
  data = wavAnalysis1( wavfn )
  data.calcDis()
  puts data.sprint("### 1st Silence ")
  
end



