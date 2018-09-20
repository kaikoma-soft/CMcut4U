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
  attr_accessor :fixfn, :metafn
  
  def initialize( ts )
    @tsfn  = ts                 # TS file name

    if ts =~ /(.*)\/(.*?)\/(.*)\.(ts|mp4)$/
      @basedir = $1
      @dir = $2
      @base = $3
      @ext  = $4
    end

    @logotablefn = sprintf("%s/logo-table.yaml",@basedir)
    @fixfn  = sprintf("%s/%s/fix.yaml",@basedir,@dir)

    @chapfn = sprintf("%s/%s/%s.chapList",Outdir,@dir,@base )
    @mp4fn  = sprintf("%s/%s/%s.mp4",Outdir,@dir,@base )
    
    @workd    = sprintf("%s/%s/%s", Workdir, @dir, @base )
    @cmcutLog = @workd + "/cmcut.log"
    @wavfn    = @workd + "/tmp.wav"
    @picdir   = @workd + "/SS"
    @metafn   = @workd + "/ffmeta.ini"

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
    #@duration = lt[ :duration ]
    #@chapNum = lt[ :chapNum ]
  end
  
end


if File.basename($0) == "FilePara.rb"
  $: << File.dirname( $0 )
  require 'const.rb'
  

  pp FilePara.new( TestTS )
  
end
