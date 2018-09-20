#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pp'
require 'shellwords'
require 'benchmark'
require 'nkf'
require 'fileutils'

require  'const.rb'
require_relative 'Ffmpeg.rb'
require_relative 'common.rb'
require_relative 'logoAnalysis.rb'
require_relative 'ts2pngwav.rb'
require_relative 'wavAnalysis.rb'


#
#  chapter 毎に encode してから結合する。
#
def  ts2mp4( fp, chap )

  chap.setMtime( File.mtime( fp.chapfn ) )

  #
  # 録画時間のチェック
  #
  ffmpeg = Ffmpeg.new( fp.tsfn )
  prob = ffmpeg.getTSinfo( fp.tsfn )
  
  raise if prob[:duration2] == nil
  sa = chap.duration - prob[ :duration2 ]
  if sa.abs > 10
    errLog (sprintf("Error: Recording time isn't identical. (%5.2f != %5.2f)\n",
                    chap.duration, prob[ :duration2 ]))
    return
  end
  
  
  #
  #  チャプター毎に mp4 化
  #
  i = 1
  cmList = []
  mainList = []
  
  chap.each do |c|
    next if c.type == :EOF

    ss = chap.getStartTime(c)
    w  = c.width
    type = "H"
    type = "C"  if c.type == :CM
    outf = sprintf("%s/tmp-%02d-%s.mp4", fp.workd, i, type )
    makePath( outf )

    opt = { :outfn  =>  outf,
            :s      => $nomalSize,
            :vf     => "yadif=0:-1:1",
          }
    
    if $opt[:fade] == true
      fft = $ffmpeg_fadetime
      ss -= fft
      if ss < 0
        ss = 0
        w += fft
      else
        w  += fft * 2
      end
      opt[:fade]=sprintf("fade=t=in:st=0.1:d=%.2f,fade=t=out:st=%.2f:d=%.2f",
                         fft, w - fft + 0.25, fft )
    end
    opt[ :ss ] = Common::sec2min( ss )
    opt[ :t ]  = sprintf("%.2f", w + 0.25 )

    debugFlag = false
    if $opt[:cmsize] == true or type =~ /^C/
      opt[ :s ] = $comSize
      debugFlag = true
    elsif prob[:width].to_i < 1280
      opt[ :s ] = sprintf("%sx%s ",prob[:width],prob[:height])
    end
    
    if c.type == :CM
      cmList << outf
    else
      mainList << outf
    end
    
    if oldFile?( outf, chap.mtime )
      ffmpeg.ts2x265( opt,debugFlag )
    end

    if $opt[:D] == false
      unless  test( ?f, outf )
        errLog("output check error")
        exit
      end
    end
    
    i += 1
  end

  #
  #  連結して最終出力
  #
  if mainList.size > 0
    if oldFile?( fp.mp4fn, chap.mtime )
      metafn = chap.makeMeta( fp )
      fname = sprintf("%s/tmp-main.txt",fp.workd)
      ffmpeg.concat( mainList, fname, fp.mp4fn, metafn )
      mainList << fname
    end
  end

  
end




if File.basename($0) == "ts2mp4.rb"
  $: << File.dirname( $0 )
  
  $opt = {
    :d => false,                # debug
    :D => false,
  }

end



