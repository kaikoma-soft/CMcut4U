#!/usr/bin/ruby
# -*- coding: utf-8 -*-
#
#
require 'optparse'
require 'pp'

$: << File.dirname( $0 )
require 'const.rb'
require_relative 'lib/common.rb'
require_relative 'lib/Chap.rb'
require_relative 'lib/FilePara.rb'

require_relative 'lib/_override.rb'

class CmCuterChk

  class Epi < Array

    attr_accessor :tfc, :comment
    attr_accessor :err
    attr_accessor :duration

    @@st = Struct.new("Epi",
                      :fname,     # file name
                      :epiNum,    # 話数
                      :chapNum,   # チャプター数
                      :honpen,    # 本編の長さ
                      :mp4,       #  mp4 があるか
                      :res )      # 判定結果
    def initialize()
      super
      @tfc = 0
      @comment = ""
      @err = nil
      @duration = 0
    end

    def add( fname, en, cn, hon, mp4, res )
      self << @@st.new( fname, en, cn, hon, mp4, res  )
    end


    def print( dir)

      printf("\n>>>>>  %s  <<<<<<<\n",dir )
      printf(" ( %s )\n", comment ) if comment != nil
      puts

      printf("No       Name    mp4 chap   duration      result\n")
      i = 1
      self.each do |b|

        mp4 = b.mp4 == true ? "○" : "✕"
        chapNum = b.chapNum == nil ? "-" : sprintf("%2d",b.chapNum )
        honpen  = b.honpen  == nil ? "-" : sprintf("%6.1f",b.honpen )

        if @duration != nil and @duration.size > 0
          gosa1 = gosa2 = 99999
          @duration.map do |x|
            y = b.honpen - x
            if y.abs < gosa1
              gosa1 = y.abs
              gosa2 = y
            end
          end

          if b.honpen != 0 and gosa1 > 1
            honpen += sprintf("(%+d)",gosa2 )
          end
        end

        res = b.res == nil ? "" : b.res

        printf("%2d %10s     %s   %2s     %-14s %s\n",
               i, b.epiNum, mp4, chapNum, honpen, res )
        i += 1
      end
    end


    def getStatus( fname )
      self.each do |tmp|
        if tmp.fname == fname
          return tmp.res
        end
      end
      nil
    end


  end


  def chkTitle( dir, fp )

    tsdir = TSdir + "/" + dir
    mp4dir = "#{Outdir}/#{dir}"
    data = Epi.new

    if test( ?f,"#{tsdir}/#{Skip}" ) or test( ?f,"#{tsdir}/#{CmcutSkip}" )
      data.err = sprintf("\n# %s Skip\n\n",dir ) if $opt[:ngOnly] == false
      return data
    end

    # リスト作成
    dirs = []
    dirs += Dir.entries( tsdir ) if test(?d, tsdir )
    dirs += Dir.entries( mp4dir ) if test(?d, mp4dir )
    tsList = {}
    dirs.each do |f|
      if f =~ /(.*?)\.(ts|mp4)$/
        tsList[ $1 ] = 0
      end
    end

    tfc = 0                       # total fail count
    ttc = 0                       # total test count
    comment = ""
    tsList.keys.sort.each do |fname|

      chapfn = sprintf("%s/%s/%s/chapList.txt", Workdir,dir,fname)
      mp4fn  = sprintf("%s/%s.mp4", mp4dir,fname )
      chap = Chap.new                     # チャプター
      mp4 = false
      hon = 0
      result = nil
      fc = 0                      # fail count
      tc = 0                      # test count

      if test( ?f, mp4fn )
        mp4 = true
      else
        fc += 1 if $opt[:test] == false
      end

      # 話数の抽出
      wa = fname
      if fname =~ /第(\d+)(話|番)/     #
        wa = $1
      elsif fname =~ /第([一二三四五六七八九十]+)(話|番)/     #
        wa = $1
      elsif fname =~ /\#(\d+)/     #
        wa = $1
      elsif fname =~ /(\d+)$/     #
        wa = $1
      elsif fname =~ /([\-\d\.]+)/
        wa = $1
      elsif fname =~ /(\d+)/
        wa = $1
      end

      data.duration = fp.duration
      if fp.chapNum != nil and fp.chapNum.size > 0
        comment = sprintf("chapNum=%s", fp.chapNum.join(",") )
      end
      if fp.duration != nil and fp.duration.size > 0
        comment += sprintf(", duration=%s", fp.duration.join(",") )
      end

      if test( ?f, chapfn )
        chap.restore( chapfn )
        hon = chap.getHonPenTime()
        # if fp.opening_delay != nil
        #   hon -= fp.opening_delay
        # end
        # if fp.closeing_delay != nil
        #   hon += fp.closeing_delay
        # end
        chap2 = chap.size == 0 ? nil : chap.size

        if fp.chapNum != nil and fp.chapNum.size > 0
          fc += 1 unless fp.chapNum.include?( chap2 )
          tc += 1
        end
        if fp.duration != nil and fp.duration.size > 0
          tc += 1
          flag = false
          fp.duration.each do |d|
            next if d == nil
            if hon.between?( d - $opt[:sa], d + $opt[:sa] ) == true
              flag = true
              break
            end
          end
          fc += 1 if flag == false
          tc += 1
        end
      else
        result = "-"
      end

      if fc > 0
        result = "NG" if result == nil
        tfc += 1
      else
        result = "OK" if result == nil
      end
      ttc += tc

      data.add( chapfn, wa, chap2, hon, mp4, result )
    end
    data.comment = comment
    data.tfc = tfc
    data
  end

end



if File.basename($0) == "cmcuterChk.rb"
  $: << File.dirname( $0 )

  require_relative 'lib/opt.rb'

  logotable = Common::loadLogoTable()


  #
  #  対象番組の検索
  #
  (Dir.entries( TSdir ) + Dir.entries( Outdir )).sort.uniq.each do |dir|
    next if dir == "." or dir == ".."
    if $opt[:dir] != nil
      next if $opt[:dir] != dir
    end

    path1 = TSdir + "/" + dir
    path2 = Outdir + "/" + dir

    if test(?d, path1 ) or test(?d, path2 )
      fp = FilePara.new( path1 )
      fp.setLogoTable( logotable[ dir ], dir )
      if fp.ignore_check == true
        printf("\n# %s Skip\n\n",dir ) if $opt[:ngOnly] == false
        next
      end

      if ( data = CmCuterChk.new.chkTitle( dir, fp ) ) != nil
        if data.err != nil
          puts( data.err )
        else
          if $opt[:ngOnly] == false or data.tfc > 0
            data.print( dir  )
          end
        end
      end
    end
  end

end
