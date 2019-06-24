#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#

#
#  ファイル名等のパラメータを格納
#
require 'pp'

class FilePara

  attr_accessor :tspath, :tsfn,:basedir,:chapfn,:mp4fn, :logofn, :cmlogofn
  attr_accessor :dir, :base, :logotablefn, :cmcutLog, :picdir, :wavfn, :workd
  attr_accessor :duration, :chapNum, :position
  attr_accessor :fixfn, :metafn, :cutSkip, :chapHash
  attr_accessor :monolingual, :audio_only, :ffmpeg_vfopt
  attr_accessor :fade_inout, :end_of_silent, :ignore_check, :ignore_endcard
  attr_accessor :opening_delay, :closeing_delay, :nhk_type, :mark0_stime
  
  def initialize( ts )
    @tsfn  = ts                 # TS file name

    if ts =~ /(.*)\/(.*?)\/(.*)\.(ts|mp4)$/
      @basedir = $1
      @dir = $2
      @base = $3
      @ext  = $4
    end

    @logotablefn = sprintf("%s/logo-table.yaml",@basedir)
    @fixfn  = sprintf("%s/%s/fix2.yaml",@basedir,@dir)

    @chapfnOld = sprintf("%s/%s/%s.chapList",Outdir,@dir,@base )
    @mp4fn  = sprintf("%s/%s/%s.mp4",Outdir,@dir,@base )
    
    @workd     = sprintf("%s/%s/%s", Workdir, @dir, @base )
    @cmcutLog  = @workd + "/cmcut.log"
    @wavfn     = @workd + "/tmp.wav"
    @picdir    = @workd + "/SS"
    @metafn    = @workd + "/ffmeta.ini"
    @chapHash  = @workd + "/chapList.sha"
    @chapfn    = @workd + "/chapList.txt"

    @cutSkip = false
    cutSkipFn = sprintf("%s/%s/%s",@basedir,@dir,CmcutSkip)
    @cutSkip = true if test( ?f, cutSkipFn )

    #moveChapList()
  end


  def setLogofn( str )
    @logofn = sprintf("%s/%s",LogoDir,str )
    return nil unless test(?f,@logofn )
    @logofn
  end

  def createSymList( name,min,max )
    list = [ name.to_sym ] + min.upto(max).map{ |n| "#{name}#{n}".to_sym }
  end
  
  #
  #  logo テーブルの情報格納
  #
  def setLogoTable( lt, dir )

    if lt == nil
      errLog("Warnnig: LogoTable id nil (#{dir})")
      return
    end
                         
    @cmlogofn = []
    createSymList( "cmlogofn", 0, 9 ).each do |sym|
      if lt[ sym ] != nil
        fn = sprintf("%s/%s",LogoDir, lt[ sym ] )
        if test( ?f, fn )
          @cmlogofn << fn
        else
          errLog("Error: logo file not found (#{fn})")
        end
      end
    end

    @logofn = []
    createSymList( "logofn", 0, 9 ).each do |sym|
      if lt[ sym ] != nil
        fn = sprintf("%s/%s",LogoDir, lt[ sym ] )
        if test( ?f, fn )
          @logofn << fn
        else
          errLog("Error: logo file not found (#{fn})")
        end
      end
    end

    @duration = []
    createSymList( "duration", 0, 9 ).each do |sym|
      @duration << lt[ sym ] if lt[ sym ] != nil
    end
    
    @chapNum = []
    createSymList( "chapNum", 0, 9 ).each do |sym|
      @chapNum << lt[ sym ] if lt[ sym ] != nil
    end
    
    @position = lt[ :position ]
    if lt[ :monolingual ] == nil # Only the right channel of audio
      @monolingual = nil
    else
      @monolingual = lt[ :monolingual ].to_i
    end
    @audio_only     = lt[ :audio_only ] # logo解析を行わず、音声のみで処理する。
    @ffmpeg_vfopt   = lt[ :ffmpeg_vfopt ]
    @fade_inout     = lt[ :fade_inout ]
    @end_of_silent  = lt[ :end_of_silent ] # 長い無音期間の最後を境界にする。
    @nhk_type       = !!lt[ :nhk_type ]    # 途中CM無し、前後に長い無音期間あり
    @ignore_check   = !!lt[ :ignore_check ] # cmcuterChk の対象外とする。
    @ignore_endcard = !!lt[ :ignore_endcard ] # EndCard 検出を無効化
    @mp4skip        = !!lt[ :mp4skip ]    # このディレクトリは無視する
    @cmcut_skip     = !!lt[ :cmcut_skip ] # CMカット処理は行わず、丸ごと
    if lt[ :opening_delay ] != nil
      @opening_delay = lt[ :opening_delay ].to_f # 本編開始の微調整
    else
      @opening_delay = nil
    end
    if lt[ :closeing_delay ] != nil
      @closeing_delay = lt[ :closeing_delay ].to_f # 本編終了の微調整
    else
      @closeing_delay = nil
    end
    if lt[ :mark0_stime ] != nil
      @mark0_stime = lt[:mark0_stime].to_f # mark0 の無音期間の長さ
    else
      @mark0_stime = 2.0
    end
    
    #@duration = lt[ :duration ]
    #@chapNum = lt[ :chapNum ]
  end

  #
  #  chapList を mp4 の下から work へ移動する。
  #
  # def moveChapList()
  #   if test( ?f, @chapfnOld )
  #     unless test( ?f, @chapfn )
  #       dir = File.dirname( @chapfn )
  #       if test( ?d, dir )
  #         hash = fileDigest( @chapfnOld )
  #         saveDigest( @chapHash, hash )
  #         File.rename( @chapfnOld, @chapfn )
  #         printf("move %s\n",@chapfnOld )
  #       end
  #     end
  #   end
  #   if test( ?f, @chapfn )
  #     unless test( ?f, @chapHash )
  #       hash = fileDigest( @chapfn )
  #       saveDigest( @chapHash, hash )
  #       printf("make hash %s\n", @chapHash )
  #     end
  #   end
  # end
  
end


if File.basename($0) == "FilePara.rb"
  $: << File.dirname( $0 )
  require 'const.rb'
  

  pp FilePara.new( TestTS )
  
end
