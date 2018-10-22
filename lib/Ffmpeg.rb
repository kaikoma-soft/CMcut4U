#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#
#

require 'pp'
require 'optparse'
require 'nkf'


class Ffmpeg

  def initialize( ts )
    unless test( ?f, ts )
      raise "ts file not found (#{ts})"
    end
    @tsfn = ts
    if $opt[:d] == true
      @logLevel = %w( -hide_banner )
    else
      @logLevel = %w( -loglevel fatal -hide_banner )
    end
    @bin = $ffmpeg_bin
    #@bin = "/usr/local/bin/ffmpeg"
  end
  
  #
  #  実行時間表示付き system
  #
  def system2( bin, *cmd )

    errLog( sprintf("%s %s",bin,cmd.join(" ") ))
    if $opt[:D] == false
      t = Benchmark.realtime { system(bin, *cmd ) }
      errLog( sprintf("%.2f Sec\n",t ))
    end
  end

  
  #
  #  tmp meta情報ファイルの作成
  #
  def makeTmpMeta( metafn, endtime )
    et = endtime.to_f
    starttime = 0
    n = 1
    buff = [ ";FFMETADATA1","", ]
    [ et * 0.5, et * 0.8, et * 0.9, et * 0.99, et ].each do |time|
      if ( ( et - time ) > 5 ) or time == et
        time = time.to_i
        buff << "[CHAPTER]"
        buff << "TIMEBASE=1/1"
        buff << "START=#{starttime}"
        buff << "END=#{time}"
        buff << "title=chapter #{n}"
        buff << ""
        starttime = time
        n += 1
      end
    end

    File.open( metafn, "w" ) do |f|
      buff.each do |s|
        f.puts(s)
      end
    end
    metafn
  end


  #
  #  チャプター毎の mp4 ファイルを連結
  #
  def concat( list, fname, outf, metafn )

    makePath( outf )
    
    File.open( fname,"w") do |fp|
      list.each do |fn|
        fp.printf("file %s\n", Shellwords.escape(fn) )
      end
    end

    unless test(?d, outf ) 
      arg = @logLevel +
            %W( -f concat -safe 0 -i #{fname} -c:v copy -c:a copy ) +
            %W( -y #{outf} )
      if metafn != nil and test( ?f, metafn )
        arg += %W( -i #{metafn} -map_metadata 1 )
      end
      #pp arg
      system2( @bin, *arg )
    end
  end

  

  #
  #  ffprob
  #
  def getTSinfo( opt = nil )
    
    r = {}
    r[ :fname ] = @tsfn
    keys = %w( width height codec_long_name duration field_order display_aspect_ratio )
    arg = [  ]
    arg += %W( -pretty -hide_banner -show_streams  #{@tsfn} )
    IO.popen( ["ffprobe", *arg], "r",:err=>[:child, :out] ) do |fp|
      fp.each_line do |line|
        line = NKF::nkf("-w",line.chomp)
        keys.each do |k|
          if line =~ /^#{k}=(.*)/
            if $1 != "N/A"
              r[ k.to_sym ] = $1 if r[ k.to_sym ] == nil
            end
          elsif line =~ /^\s+Duration: (.*?),/
            r[ :duration ] = $1 if r[ :duration ] == nil
          end
        end
      end
    end

    if r[:duration] != nil
      if r[:duration] =~ /(\d):(\d+):([\d\.]+)/
        r[:duration2] = $1.to_i * 3600 + $2.to_i * 60 + $3.to_f
      end
    end

    [ :duration2, :width, :height ].each do |key|
      if r[ key ] == nil
        raise "#{key.to_s} is nil #{@tsfn}"
      end
    end
    r
  end

  
  #
  #  screen shot 
  #
  def ts2ss( opt )
    arg = @logLevel +
          %W( -threads #{CPU_core} -i #{@tsfn} ) +
          %W( -r #{SS_frame_rate} -f image2 -vframes #{opt[:vf]} ) +
          %W( -vf crop=#{opt[:w]}:#{opt[:h]}:#{opt[:x2]}:#{opt[:y2]} ) +
          %W( -vcodec mjpeg -y #{opt[:picdir]}/ss_%05d.jpg )
    system2( @bin, *arg )

    # check
    unless test( ?f, opt[:picdir] + "/ss_00001.jpg" )
      mesg = "jpg file can't create"
      errLog(mesg)
      raise mesg
    end
  end

  #
  #  wav 変換
  #
  def ts2wav( opt )
    arg = @logLevel +
          %W( -threads #{CPU_core} -i #{@tsfn} ) +
          %W( -vn -ac 1 -ar #{WavRatio} -acodec pcm_s16le -f wav ) +
          %W( -y #{opt[:outfn]} ) 
    system2( @bin, *arg )
  end

  #
  #  メタデータを追加
  #
  def addMeta( opt )
    makeTmpMeta( opt[:meta], opt[:t] )
    out2 = opt[:outfn].sub(/\.mp4$/,"-tmp.mp4")
    arg = @logLevel + %W( -y )
    arg += %W( -i #{opt[:outfn]} )
    arg += %W( -i #{opt[:meta]} -map_metadata 1 )
    arg += %W( -codec copy #{out2} )
    system2( @bin, *arg )
    if test( ?s, out2 )
      File.unlink( opt[:outfn] )
      File.rename( out2, opt[:outfn] )
    else
      errLog( "fail addMeta()" )
    end
  end
  
  #
  #  x265 に変換
  #
  def ts2x265( opt, debug = false )
      
    arg = @logLevel + %W( -y -analyzeduration 60M -probesize 100M )
    arg += %W( -ss #{opt[:ss]} -t #{opt[:t]} ) if opt[:ss] != nil
    arg += %W( -i #{@tsfn} )
    arg += %W( -vcodec libx265 -acodec aac )
    arg += %W( -movflags faststart )
    arg += %W( -x265-params --log-level=warning )
    if opt[:vf] != nil or opt[:fade] != nil
      arg += %W( -vf )
      tmp = []
      tmp << opt[:vf] if opt[:vf] != nil 
      tmp << opt[:fade] if opt[:fade] != nil 
      arg << tmp.join(",")
    end
    arg += %W( -s #{opt[:s]} )  if opt[:s] != nil
    arg += %W( -preset ultrafast ) if $opt[:d] == true  or debug == true
    arg += %W( #{opt[:outfn]} )
    system2( @bin, *arg )
  end

  #
  #  mp4 のカット編集
  #
  def mp4cut( opt )

    arg = @logLevel + %W( -y )
    arg += %W( -ss #{opt[:ss]} -t #{opt[:t]} ) if opt[:ss] != nil
    arg += %W( -i #{@tsfn} )
    arg += %W( -vcodec copy -acodec copy )
    arg += %W( #{opt[:outfn]} )
    #pp arg
    system2( @bin, *arg )
  end


end



if File.basename($0) == "Ffmpeg.rb"
  $: << File.dirname( $0 )
  require 'const.rb'
  require 'benchmark'

  $opt = { :d => true }

  ffmpeg = Ffmpeg.new( TestTS )

  type = :getTSinfo
  case type
  when :getTSinfo 
    time = Benchmark.realtime { pp ffmpeg.getTSinfo( ) } 
  when :ts2wav
    time = Benchmark.realtime {
      ffmpeg.ts2wav( outfn: "tmp.wav" )
    } 
  when :ts2ss
    w =1920
    h = 1080
    time = Benchmark.realtime do
      ffmpeg.ts2ss( vf: 1800 * Fps,
                    x1: (w * 0.2),
                    y:  (h * 0.2),
                    x2: (w * 0.8),
                    picdir: "out" )
    end
  end
  printf("%.2f Sec\n",time )

end
