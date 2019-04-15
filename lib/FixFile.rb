#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#

#require_relative 'Ranges.rb'

#
#   fix ファイル
#
class FixFile

  attr_reader :duration, :mtime, :silence, :lastframe

  None    = 0
  SelfHon = 1
  SelfCM  = 2
  AllHon  = 3
  AllCM   = 4
  
  @@d = Struct.new(:fname,      # ファイル名
                   :type,       # タイプ
                   :time,       # 秒数
                  )
  
  include Common

  def initialize(  )
    super
    @data = []
  end

  #
  # fix ファイルの読み込み
  #
  def  readFix( fp )
    fix = []
    if fp != nil 
      if test( ?f, fp.fixfn )
        fix = YAML.load_file( fp.fixfn  )
      end
      
      fix.each do |r|
        time = 0
        type = None
        if r[0].downcase == "all"
          type = :all
        elsif r[0] == fp.base or r[0] == fp.base + ".ts"
          type = :self
        else
          next
        end

        if r[1] =~ /(\d+):(\d+)/
          time = $1.to_i * 60 + $2.to_i
        else
          time = r[1].to_f
        end
        
        case r[2]
        when /^h/i then type = type == :all ? AllHon : SelfHon
        when /^c/i then type = type == :all ? AllCM : SelfCM
        end
        @data << @@d.new( r[0], type, time )
      end
    else
      return nil
    end
    @data
  end

  def sprint()
    r = []
    if @data.size > 0
      r << ("-" * 10 + "  fix data  " + "-" * 10 )
      @data.each do |tmp|
        type = "CM" if tmp.type == AllCM or tmp.type == SelfCM
        type = "HonPen" if tmp.type == AllHon or tmp.type == SelfHon
        r << sprintf("%s : %s : %s",tmp.fname, type,tmp.time.round(1))
      end
      r << ("-" * 32 )
    end
    r
  end

  #
  #  
  #
  def hantei( tstart, tend )
    @data.each do |d|
      if d.time.between?(tstart, tend  )
        return d.type
        break
      end
    end
    None
  end

  #
  #  
  #
  def hantei2( tstart )
    s1 = tstart.round(1)
    @data.each do |d|
      s2 = d.time.round(1)
      if s1 == s2
        return d.type
        break
      end
    end
    None
  end
  
  def typeStr( type )
    types = %w( - 本編 CM 全話共通-本編 全話共通-CM )
    return types[ type ]
  end


  #
  #  fix ファイルに merge write
  #
  def mergeFix( fp, data )
    fix = []
    fix2 = []
    if fp != nil 
      if test( ?f, fp.fixfn )
        fix = YAML.load_file( fp.fixfn  )
      end
      
      fix.each do |r|
        if r[0].downcase == "all" or r[0] == fp.base or r[0] == fp.base + ".ts"
          next
        end
        fix2 << [ r[0], r[1], r[2] ]
      end
    else
      return nil
    end

    data.each do |d|
      case d[:type]
      when SelfHon
        fname = fp.base + ".ts"
        type  = "HonPen"
      when SelfCM
        fname = fp.base + ".ts"
        type  = "CM"
      when AllHon
        fname = "all"
        type  = "HonPen"
      when AllCM
        fname = "all"
        type  = "CM"
      else
        next
      end
      fix2 << [ fname, d[:time], type ]
    end

    File.open( fp.fixfn,"w") do |fp|
      fp.puts YAML.dump( fix2 )
    end
  end
  
  #
  # fix ファイルの読み込み(旧)
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
            if chapH != nil
              chapC = Chap.new().init( chapH.getLastTime(), :CM )
            end
          end
          chapC.insertData( time )
        end
        fix2 << sprintf("%s : %.1f : %s",r[0],time,r[2])
      end
    end
    if chapC != nil and chapH != nil
      if chapC.last[:type] != -1
        chapC.add( chapH.getLastTime(), -1 )
      end
    end

    if fix2.size > 0
      errLog("-" * 10 + "  fix data  " + "-" * 10 )
      fix2.each { |tmp| errLog(tmp) }
      errLog("-" * 32 )
    end

    [ chapH, chapC ]
  end

end  
  





