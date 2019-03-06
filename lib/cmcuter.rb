#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pp'
require 'shellwords'
require 'benchmark'

$: << File.dirname( $0 )
$: << File.dirname( $0 ).sub(/\/lib/,'')

require_relative 'FilePara.rb'
require_relative 'common.rb'
require_relative 'logoAnalysis.rb'
require_relative 'ts2mp4.rb'
require_relative 'ts2png.rb'
require_relative 'ts2wav.rb'
require_relative 'wavAnalysis.rb'
require_relative 'FixFile.rb'



#
#  CMカット計算を実行するかどうかの判定
#
def goCalc?( fp )

  # chapList が存在しているか？
  if test(?f, fp.chapfn )
    if test(?f, fp.mp4fn )
      if File.mtime( fp.mp4fn ) < File.mtime( fp.chapfn )
        # 現在のchapList のハッシュと過去のは一致するか？
        if $opt[:ic] == false
          hash_now = fileDigest( fp.chapfn )
          hash_old = loadDigest( fp.chapHash )
          if hash_old == nil
            errLog("#old hash not found") if $opt[:d] == true
            return true
          end
          unless hash_old == hash_now
            errLog("#hash diff") if $opt[:d] == true
            return true
          end
        end
      end
    end
  else
    errLog("#chapList not found") if $opt[:d] == true
    return true
  end
  return false
end


#
#   TS ファイルと logo ファイルを指定して、CM
#
def cmcutCalc( fp, force = false )

  chap2 = sdata = nil
  
  if goCalc?( fp ) == true or force == true
    $cmcutLog = fp.cmcutLog
    File.delete( $cmcutLog ) if test(?f, $cmcutLog )

    # TS から wav を抽出
    wavfn = ts2wav( fp )
      
    # sound データ取得
    sdata = wavAnalysis1( wavfn )
    last = sdata.getLastframe()
    sdata.calcDis()
    errLog( sdata.sprint("### Silence data from wav") ) if $opt[:d] == true

    #
    #  映像の時間と音声時間を比較して、違う場合は補正を掛ける。
    #
    ffmpeg = Ffmpeg.new( fp.tsfn )
    prob = ffmpeg.getTSinfo( fp.tsfn )
  
    raise if prob[:duration2] == nil
    hosei = prob[ :duration2 ] / last
    if hosei.abs > 1.001
      errLog (sprintf("\nWarning: Recording time is different. (%5.2f != %5.2f %2.2f%%)\n\n",last, prob[ :duration2 ], hosei * 100 ))

      # 補正
      sdata.each do |s|
        s.start *= hosei
        s.end   *= hosei
      end
      sdata.calcDis()
      errLog( sdata.sprint("### Silence data from wav after correct") ) if $opt[:d] == true
    end
    
    if fp.audio_only != true

      # TS から ScreenShot を抽出
      picdir = ts2png( fp )

      if fp.logofn == nil or fp.logofn.size == 0
        errLog("Warning: not found in logofile\n")
        return [nil,nil]
      end

      # logo データ取得
      ( chapH, chapC ) = logoAnalysis( fp, picdir )
      if chapH.size < 5 and chapH.duration > 600
        errLog("Error: The number of chapters is too small.\n")
        return [nil,nil]
      end
    else
      chapH = Chap.new().init( last )
      chapC = Chap.new().init( last, :CM )
    end

    # fix ファイルの読み込み
    ff = FixFile.new()
    ( chapH, chapC ) = ff.loadFix( fp, chapH, chapC )

    errLog(chapH.sprint("### Honpen Chapter from logo data"))
    if chapC != nil
      errLog(chapC.sprint("### CM     Chapter from logo data"))
    end

    # sound データの加工、調整
    sdata.marking1a( chapH, chapC )   # 1pass
    if fp.audio_only != true
      sdata.marking1b( ) if fp.ignore_endcard != true
      sdata.marking1c( )
      sdata.marking2( )
    else
      errLog( sdata.sprint(""))
    end

    sdata.normalization()
    errLog( sdata.sprint("### 1st adj")) if $opt[:d] == true
    sdata.marking3( )
    sdata.marking1a( chapH, chapC )      # 併合したものに対しての２回め
    sdata.sprint()                       # dummy だけど必要

    sdata.setCmRange( )
    sdata.marking4( )
    errLog( sdata.sprint("### Chapter adj "))

    chap2 = sdata.createChap( fp )
    errLog( chap2.sprint("### final Chapter List" ))

    chap2.dataDump( fp.chapfn )
  else
    chap2 = Chap.new()
    chap2.restore( fp.chapfn )
  end

  return [ chap2, sdata ]
end


#
#  CMカットせず丸ごと変換する。
#
def allConv( fp )

  return if $opt[:calcOnly] == true
  
  ffmpeg = Ffmpeg.new( fp.tsfn )

  unless test( ?f, fp.mp4fn )
    opt = { :outfn  =>  fp.mp4fn,
            :s      => $nomalSize,
            :vf     => %w( yadif=0:-1:1 ) ,
            :monolingual => fp.monolingual,
          }
    makePath( fp.mp4fn )
    ffmpeg.ts2x265( opt )
  end
end


if File.basename($0) == "cmcuter.rb"
  require_relative 'dataClear.rb'
  require_relative 'opt.rb'

  if test( ?f, Tablefn )
    logotable = YAML.load_file( Tablefn )
  else
    raise "logo table file not found (#{Tablefn})"
  end

  ARGV.each do |fn|
    if test( ?f, fn )
      fp = FilePara.new( fn )
      fp.setLogoTable( logotable[ fp.dir ], fp.dir )
      $cmcutLog = fp.cmcutLog
      
      dataClear( fp, $opt[:delLevel] )

      if fp.cutSkip == true
        unless test(?f, fp.mp4fn )
          t = Benchmark.realtime { allConv( fp ) }
          errLog(sprintf("allConv() %.2f Sec\n",t))
        end
      else
        chap = nil
        t = Benchmark.realtime { ( chap, sdata ) = cmcutCalc( fp ) }
        errLog(sprintf("cmcutCalc() %.2f Sec\n",t))

        if $opt[:calcOnly] == false
          t = Benchmark.realtime { ts2mp4( fp, chap ) }
          errLog(sprintf("tmp2mp4() %.2f Sec\n",t))
        end
      end
    end
  end
  
end


