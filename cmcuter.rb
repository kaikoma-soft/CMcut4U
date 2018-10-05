#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pp'
require 'shellwords'
require 'benchmark'

$: << File.dirname( $0 )
require_relative 'lib/FilePara.rb'
require_relative 'lib/common.rb'
require_relative 'lib/logoAnalysis.rb'
require_relative 'lib/ts2mp4.rb'
require_relative 'lib/ts2pngwav.rb'
require_relative 'lib/wavAnalysis.rb'


#
# fix ファイルの読み込み
#
def  loadFix( fp, chapH, chapC )
  fix = []
  if test( ?f, fp.fixfn )
    fix = YAML.load_file( fp.fixfn  )
  end

  fix2 = []
  fix.each do |r|
    if r[0].downcase == "all" or r[0] == fp.base or r[0] == fp.base + ".ts"
      if r[1] =~ /(\d+):(\d+)/
        time = $1.to_i * 60 + $2.to_i
      else
        time = r[1].to_f
      end
      if r[2] =~ /^h/i
        chapH.insertData( time )
      elsif r[2] =~ /^c/i
        if chapC == nil
          chapC = Chap.new
          chapC.setcmDataFlag()
          chapC.add( 0, 0 )
          chapC.add( chapH.getLastTime(), -1 )
        end
        chapC.insertData( time )
      end
      fix2 << sprintf("%s : %d : %s",r[0],time,r[2])
    end
  end

  if fix2.size > 0
    errLog("-" * 10 + "  fix data  " + "-" * 10 )
    fix2.each { |tmp| errLog(tmp) }
    errLog("-" * 32 )
  end

  [ chapH, chapC ]
end

#
#   TS ファイルと logo ファイルを指定して、CM
#
def cmcuter( fp )
  
  if test( ?f, fp.chapfn ) == false

    $cmcutLog = fp.cmcutLog
    File.delete( $cmcutLog ) if test(?f, $cmcutLog )
    
    # TS から　wav, ScreenShot を抽出
    ( wavfn, picdir ) = ts2pngwav( fp )

    if fp.logofn == nil or fp.logofn.size == 0
      errLog("Warning: not found in logofile(#{fp.logofn})\n")
      return
    end

    # logo データ取得
    ( chapH, chapC ) = logoAnalysis( fp, picdir )

    # fix ファイルの読み込み
    ( chapH, chapC ) = loadFix( fp, chapH, chapC )

    errLog(chapH.sprint("### Honpen Chapter from logo data"))
    if chapC != nil
      errLog(chapC.sprint("### CM     Chapter from logo data"))
    end
    
    # sound データ取得
    sdata = wavAnalysis1( wavfn )
    sdata.calcDis()
    #errLog( sdata.sprint("### Silence data from wav") )

    # sound データの加工、調整
    sdata.marking1a( chapH, chapC, 1 )   # 1pass
    sdata.marking1b( )
    sdata.marking1c( )

    sdata.marking2( )
    sdata.normalization()
    errLog( sdata.sprint("### 1st adj"))

    sdata.setCmRange( )
    sdata.marking3( )
    errLog( sdata.sprint("### 2nd adj"))

    chap2 = sdata.createChap( )
    errLog( chap2.sprint("### final Chapter List" ))

    chap2.dataDump( fp.chapfn )
  else
    chap2 = Chap.new()
    chap2.restore( fp.chapfn )
  end

  return if $opt[:calcOnly] == true

  ts2mp4( fp, chap2 )
  
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
            :vf     => "yadif=0:-1:1",
          }
    ffmpeg.ts2x265( opt )
  end
end


if File.basename($0) == "cmcuter.rb"
  $: << File.dirname( $0 )
  require_relative 'lib/dataClear.rb'
  
  OptionParser.new do |opt|
    opt.on('-d') { $opt[:d] = true }
    opt.on('--co') { |v| $opt[:calcOnly] = true  }
    opt.on('--dd n') { |v| $opt[:delLevel] = v.to_i  } # delete data
    opt.on('--cm') { |v| $opt[ :cmsize] = true  }      # force CM size
    opt.parse!(ARGV)
  end

  if test( ?f, Tablefn )
    logotable = YAML.load_file( Tablefn )
  else
    raise "logo table file not found (#{Tablefn})"
  end

  ARGV.each do |fn|
    fp = FilePara.new( fn )
    fp.setLogoTable( logotable[ fp.dir ], fp.dir )
    $cmcutLog = fp.cmcutLog

    dataClear( fp, $opt[:delLevel] )
  
    printf("cmcuter() %.2f Sec\n", Benchmark.realtime { cmcuter( fp ) })
  end
  
end


