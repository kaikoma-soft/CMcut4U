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
=begin  
  sa = chap.duration - prob[ :duration2 ]
  hosei = ( sa.to_f / prob[ :duration2 ] ) 
  if hosei.abs > 0.001
    errLog (sprintf("Warning: Recording time is different. (%5.2f != %5.2f %2.2f%%)\n",chap.duration, prob[ :duration2 ], hosei * 100 ))

    # 補正
    chap.each do |c|
      c.time = c.time - ( hosei * prob[ :duration2 ] )
    end
  end
=end
  
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
    metaf = outf.sub(/\.mp4/,".ini").sub(/\/tmp/,"/meta-tmp")

    opt = { :outfn  =>  outf,
            :s      => $nomalSize,
            :vf     => %w( yadif=0:-1:1 ) ,
            :meta   => metaf,
            :monolingual => fp.monolingual,
          }
    if fp.ffmpeg_vfopt != nil
      opt[ :vf ] += fp.ffmpeg_vfopt.split()
    end
    
    if $opt[:fade] == true and fp.fade_inout != false
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
      opt[ :s ] = $cmSize
      debugFlag = true
    elsif prob[:width].to_i < 1280
      opt[ :s ] = nil # サイズそのまま
      # opt[ :s ] = sprintf("%sx%s ",prob[:width],prob[:height])
    end
    
    if c.type == :CM
      cmList << outf
    else
      mainList << outf
    end
    
    if oldFile?( outf, chap.mtime )
      ffmpeg.ts2x265( opt,debugFlag )
      #ffmpeg.addMeta( opt )
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

  #
  # chapList のhash値を保存
  #
  hash = fileDigest( fp.chapfn )
  saveDigest( fp.chapHash,hash )
  
end




if File.basename($0) == "ts2mp4.rb"
  $: << File.dirname( $0 )
  
  $opt = {
    :d => false,                # debug
    :D => false,
  }

end



