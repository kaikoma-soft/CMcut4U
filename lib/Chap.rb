#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
#

require_relative 'Ranges.rb'

#
#   チャプター
#
class Chap < Array

  attr_reader :duration, :mtime, :silence, :lastframe
  attr_accessor :cmRange, :cmDataFlag

  @@st = Struct.new(:time,      # 秒数
                    :type,      # タイプ
                    :width)     # 次chap までの幅

  include Common

  def initialize()
    super
    @duration = nil
    @mtime = nil                # chapList のmtime
    @cmDataFlag = false         # CM データを保存する
    self
  end

  def setcmDataFlag()
    @cmDataFlag = true          # CM データを保存する
  end

  def setMtime( t )
    @mtime = t
  end

  # 最低限の状態にセットする。
  def init( last, type = :HON )
    if type != :HON
      setcmDataFlag()
    end
    add( 0, 0 )
    add( last, -1 )
    self
  end

  def add(  time, logo )
    logo2 = case logo
            when 0 then :CM
            when 1 then  :HonPen
            when -1 then :EOF
            end
    self << @@st.new( time, logo2, nil )
  end

  def calcWidth()
    total = 0
    honpen = 0
    self.each_index do |i|
      if self[i+1] != nil
        next if self[i+1].time == nil

        self[i].width = ( self[i+1].time - self[i].time )
        if self[i].width < 0
          #printf("Error: ( width = %f ) < 0 in %d\n", self[i].width, self[i].time )
          self[i].width = 0
          #raise
        end
        total += self[i].width
        honpen += self[i].width if self[i].type == :HonPen
      end
    end

    @duration = total
    @honpen = honpen
  end

  def getLastTime()
    self.last.time
  end

  def getStartTime( c )
    t = c.time
    t = 0.0 if t < 0.0

    return t
  end

  #
  #  本編時間を取得
  #
  def getHonPenTime()
    hon = 0
    self.each do |c|
      if c.type == :HonPen
        hon += c.width
      end
    end
    hon
  end

  #
  #  連続した同一chapter は、後ろを削除
  #
  def delSame()
    del = []
    p = nil
    self.each do |s|
      if p != nil
        if p.type == s.type
          del << s
        end
        if p.time == s.time
          p.type = :EOF if s.type == :EOF
          del << s
        end
      end
      p = s
    end

    del.each do |d|
      #p "del #{d.time} #{d.type}"
      self.delete(d)
    end
    calcWidth()
  end


  #
  #  小さい :CM は、削除
  #
  def delmin()
    del = []

    self.each do |s|
      if s.width != nil and s.time > 1
        if (( s.width ) < 5 ) and s.type == :CM # 5秒未満
          del << s
        end
      end
    end
    del.each do |d|
      #p "del #{d.time} #{d.type}"
      self.delete(d)
    end

    delSame()

  end


  #
  #  表示
  #
  def sprint( text = "" )
    i = 1
    r = []
    @cm = 0
    @honpen = 0
    r << "\n#{text}\n"
    self.each do |s|
      t2 = sec2min( s.time )
      w = s.width == nil ? 0 : s.width
      if self.cmDataFlag == false
        type = s.type.to_s
      else
        if s.type == :EOF
          type = "EOF"
        else
          type = s.type == :CM ? "HonPen" : "CM"
        end
      end
      r << sprintf( "%3d %6.1f (%s) %6.2f  %s\n",i, s.time, t2, w, type )
      i += 1
      if s.width != nil
        if s.type == :CM or s.type == :EOF
          @cm += s.width
        elsif s.type == :HonPen
          @honpen += s.width
        end
      end
    end

    if @duration != nil and @duration != 0
      spc = "                      "
      bar = "------------------"
      r << sprintf("%s%s\n",spc,bar)

      cmp = @cm / @duration * 100
      honp = @honpen / @duration * 100
      if self.cmDataFlag == false
        ct = "CM_Total"
        ht = "HonPen_Total"
      else
        ht = "CM_Total"
        ct = "HonPen_Total"
      end
      r << sprintf("%s%8.2f (%4.1f%%) %s\n",spc, @cm, cmp, ct )
      r << sprintf("%s%8.2f (%4.1f%%) %s\n",spc, @honpen, honp, ht)
      r << sprintf("%s%s\n",spc,bar)
      r << sprintf("%s%8.2f  Toatl\n\n",spc,duration)
    end

    r.join()
  end


  #
  #  data のダンプ
  #
  def dataDump( fpara )
    fname = fpara.chapfn
    makePath( fname )
    opening = true
    if File.open( fname, "w") do |fp|
         self.each do |s|
           type = case s.type
                  when :CM     then  "CM"
                  when :HonPen then  "HonPen"
                  when :EOF    then  "EOF"
                  else
                    p s.type
                    raise
                  end
           t = sec2min( s.time )
           fp.printf( "%s  %s\n",t, type )
         end
       end
    end
  end

  #
  #  opening,closeing delay オプションの処理
  #
  def opening_delay( fp )

    if fp.opening_delay != nil
      self.each do |s|
        if s.type == :HonPen
          s.time += fp.opening_delay
          break
        end
      end
    end
    if fp.closeing_delay != nil
      prev = nil
      self.reverse.each do |s|
        if s.type == :HonPen
          prev.time += fp.closeing_delay
          break
        end
        prev = s
      end
    end
    calcWidth()
  end


  #
  #  data のrestore
  #
  def restore( fname )

    if File.open( fname, "r") do |fp|
         fp.each_line do |line|
           next if line =~ /^#/
           if line =~ /^([\d:\.]+)\s+(\w+)/
             time = $1
             type = $2
             type = case type
                    when "CM"     then 0
                    when "HonPen" then 1
                    when "EOF"    then -1
                    else
                    p type
                    raise
                    end
             if time =~ /(\d+):(\d+):([\d.]+)/
               time = ( $1.to_f * 3600 + $2.to_f * 60 + $3.to_f )
               add( time.round(2), type )
             end
           end
         end
       end
    end
    calcWidth()
  end

  #
  # 本編情報を抜き出して ranges型に変換
  #
  def  conv2Ranges()

    ranges = Ranges.new
    prev = nil
    self.each do |c|
      if c.type == :CM or c.type == :EOF
        if prev != nil and prev.type == :HonPen
          ranges.add( prev.time, c.time )
        end
      end
      prev = c
    end
    ranges
  end


  #
  #  データを挿入
  #
  def insertData( time )

    self.each_index do |i|
      c = self[i]
      next if ( d = self[i+1] ) == nil

      if time.between?( c.time, d.time )
        if c.type == :CM
          self.insert( i+1, @@st.new( time+0.1, :CM, 0 ))
          self.insert( i+1, @@st.new( time, :HonPen, 0 ))
          break
        end
      end
    end
    calcWidth()
  end

  #
  #  ffmpeg meta情報ファイルを作成
  #
  def makeMeta( fp )

    buff = [ ";FFMETADATA1","", ]
    buff << "title=#{fp.base}"
    buff << ""
    n = 1
    time = 0
    self.each do |c|
      if c.type == :HonPen
        buff << "[CHAPTER]"
        buff << "TIMEBASE=1/1"
        #buff << sprintf("# -ss 00:00:00 -to 00:00:41 ",)
        buff << "START=#{time}"
        buff << "END=#{time + c.width}"
        buff << "title=chapter #{n}"
        buff << ""
        n += 1
        time += c.width
      end
    end

    #pp buff

    File.open( fp.metafn, "w" ) do |f|
      buff.each do |s|
        f.puts(s)
      end
    end

    fp.metafn
  end

end
