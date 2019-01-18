#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#

require_relative 'Ranges.rb'
require_relative 'Chap.rb'

#
#  無音期間の 開始-終了の配列
#
class Silence < Array

  attr_reader :lastframe
  
  @@t = Struct.new(:start,      # 開始
                   :end,        # 終了
                   :mid,        # 中央
                   :dis,        # 一つ前との間隔
                   :flag,       # フラグ
                   :comment,    # コメント
                   :w           # 無音時間
                  )

  include Common
  
  def initialize()
    super
    @lastframe = nil
  end

  #
  #  データの追加
  #
  def add( ts, te )
    w = te - ts  
    self << @@t.new( ts,te,nil,nil,nil,nil, w )
  end

  #
  #  最終フレーム取得
  #
  def getLastframe()
    if self != nil
      if ( a = self.last ) != nil
        @lastframe = a.end
      end
    end
    @lastframe
  end
  
  #
  #  データの表示
  #
  def sprint( text = "" )
    i = 1
    r = []
    del = []
    r << sprintf( "\n" + text )
    self.each do |a|
      dis = a.dis != nil ? a.dis : 0.0
      comme = sprintf("%-7s",a.flag == nil ? "" : a.flag.to_s)
      comme += a.comment == nil ? "" : a.comment
      r << sprintf("%3d %7.1f - %7.1f (%s %3.1f)  %5.1f %s\n",
                   i, a.start, a.end, sec2min(a.start), a.w, dis, comme )
      i += 1
      del << a if a.flag == :Del
      @lastframe = a.end
    end

    del.each do |d|
      r << sprintf("delete %6d %5.1f\n",d.start, d.dis)
      self.delete( d )
    end
    
    r
  end


  #
  #  コメント欄に文字列追加
  #
  def addComment( data, str )
    if data.comment == nil
      data.comment = str
    else
      data.comment += "; " + str
    end
  end
  
  #
  #  次データとの間隔を計算
  #
  def calcDis()
    prev = nil
    self.each do |a|

      a.flag = nil if a.flag == :reserve

      a.mid = ( a.start + a.end ) / 2  if a.mid == nil
      if prev != nil
        # 無音期間が長い場合の調整
        if a.w > 1.4
          if prev.flag == :HonPen and ( a.flag == nil or a.flag == :CM )
            new = a.end - 0.5
            if a.mid != new
              a.mid = new
              addComment( a, "Long silence")
            end
          elsif a.flag == :HonPen and ( prev.flag == nil or prev.flag == :CM )
            new = a.start + 0.5
            if a.mid != new
              a.mid = new
              addComment( a, "Long silenceH")
            end
          end
        end
        old = prev.dis
        if a.flag != :Del
          prev.dis = a.mid - prev.mid
          if old != prev.dis
            if old != nil
              str = sprintf("<- %.1f",old ) 
              addComment( prev, str )
            end
          end
        end
      end
      prev = a if a.flag != :Del
    end

    @lasttime = getLastTime()
  end

  

  def chkCMtime( time, ary )
    gosa = 0.8
    sum = ary.inject(:+)
    if sum.between?( time - gosa, time + gosa )
      #errLog( sprintf(">> %f\n", sum ) )
      return true
    end
    false
  end
  


  #
  #   正規化
  #
  def normalization()

    calcDis()

    #
    # 15,30,60秒以下は,前後の時間と足して CM時間ならば 1本にまとめる
    #
    [ 135, 120, 90, 60, 45, 30, 15 ].each do |target|
      self.each_index do |i|
        a = self[i]
        if a.dis != nil and ( a.dis < target )
          #errLog( sprintf("> %d  %f\n", a.start, a.dis) )

          data1 = []
          data2 = []
          sum = 0
          i.upto( i+10 ) do |j|
            if ( a = self[j] ) != nil
              if a.flag != :Del and a.flag != :reserve and a.dis != nil
                break if a.flag == :HonPen 
                break if cmTime?( a.dis , 0.4 ) == true
                data1 << a.dis
                data2 << j
                sum += a.dis
              end
            end
          end
          while data1.size > 1
            if chkCMtime( target, data1 ) == true
              break
            end
            data1.pop
            data2.pop
          end
          if data2.size > 1        # 合体あり
            n = data2.shift
            self[n].flag = :reserve # 書き換え中
            data2.each do |m|
              self[m].flag = :Del
              #errLog( sprintf("dle> %d\n", n) )
            end
          end
        end
      end
    end
    calcDis()

  end
    


  #
  #  CM の範囲を推定
  #
  def setCmRange(  )
    
    frame = nil
    return if self.size < 2
    
    # 最初が半端ならば CM 判定
    if self[0].dis < 12
      self[0].flag = :CM if self[0].flag == nil
    end
    
    @lasttime = getLastTime()
    self.each_index do |i|
      next if self[i].dis == nil
      next if self[i].flag == :CM
      next if self[i].flag == :HonPen
      raise if self[i].flag == :Del

      tc = 0
      count = []
      tgosa = 0
      i.upto(i+10) do |n|
        if self[n].flag == :HonPen
          break
        elsif self[n].dis != nil 
          dis = self[n].dis
          gosa = self[n].w > self[n+1].w ? self[n].w : self[n+1].w
          tgosa = gosa if tgosa < gosa 
          if cmTime?( dis, gosa > 0.8 ? gosa : 0.8 ) == true
            tc += dis
            count << n 
            frame = self[n].end
          else
            break
          end
        else
          break
        end
      end

      if tc > 0
        if cmTimeAll?( tc,tgosa ) == true or ( @lasttime * 0.9 ) < frame
          count.each do |n|
            self[n].flag = :CM
            addComment( self[n], "setCm" )
          end
        end
      end
    end

    # 最後が未定ならば CM 判定
    n = self.size - 2
    self[n].flag = :CM if self[n].flag == nil
    
  end
  

  def hantei( c, s, e )
    cs = c.start
    ce = c.end
    if ( ce - cs ) > 5
      cs += 2
      ce -= 2
    end
    # if ( s - 6356 ).abs < 3
    #   p c
    #   p s
    #   p e
    # end
    return true if s.between?( cs, ce ) or e.between?( cs, ce )
    return true if s < cs and ce < e
    false
  end
      

  #
  # 本編情報,CM情報を比較しやすい形に変換
  #
  def conv2Ranges( logoH, logoC )
    @mainChap = nil
    @cmChap = nil
    if logoH != nil
      @mainChap = logoH.conv2Ranges()
    end
    if logoC != nil
      @cmChap = logoC.conv2Ranges()
    end
  end
  
  #
  #  チャプター情報から 音声情報に本編の判定を行う。
  #
  def marking1a( logoH, logoC )

    conv2Ranges( logoH, logoC )

    self.each_index do |n|
      a = self[n]
      next if a.dis == nil or a.start == nil
      next if a.flag != nil
      next if self[n+1] == nil  or self[n+1].start == nil
      next if a.dis < 1
      
      s = a.mid
      e = a.start + a.dis - 1
      if a.dis > 10             # 余裕があれば境界付近は避ける
        s += 1
        e -= 1
      end
      if @cmChap != nil          # CM判定の方が優先
        @cmChap.each do |c|
          if hantei( c, s, e ) == true
            a.flag = :CM
            break
          end
        end
      end
      if a.flag == nil
        @mainChap.each do |c|
          if hantei( c, s, e ) == true
            a.flag = :HonPen 
            break
          end
        end
      end
    end

    # 短い本編のまま EOF の場合は次番組の頭とみなし、CM化
    a = self[ self.size - 2 ]
    if a.flag == :HonPen and a.dis < 10
      a.flag = :CM
      addComment( a, "mark1a H->C" )
    end
  end

  

  #
  # 最後の本編の直後の 90秒は、エンディングとみなす
  #
  def marking1c( )
    (self.size - 1).downto( 1 ) do |n|
      a = self[n]
      next if a == nil or a.dis == nil
      next if a.flag == :Del
      break if a.flag == :HonPen
      
      dis = a.dis 
      if dis.between?( 89.5, 90.5 ) == true
        if a.flag == nil
          if self[n-1].flag == :HonPen
            a.flag = :HonPen
            addComment( a, "mark1c Ending" )
            #errLog( "Honpen #{a.start}" )
          end
        end
      end
    end
  end

  #
  # 最後近くの 5秒間の無音は エンドカード として本編扱いしてデータを分割
  #
  def marking1b( )
    (self.size - 1).downto( 1 ) do |n|
      a = self[n]
      next if a == nil or a.dis == nil
      next if a.flag == :Del
      break if a.dis > 200
      
      w = a.end - a.start
      if w > 5.0
        if a.flag == nil or a.flag == :HonPen
          st = a.start + 5.5
          #wt = a.end - st

          # 分離したものの本編/CM 判定
          flag = nil
          b = self[n+1]
          @mainChap.each do |c|
            if hantei( c, st, b.start) == true
              flag = :HonPen 
              break
            end
          end
          
          self.insert( n+1, @@t.new( st, a.end, nil,nil,flag,"insert mark1b",w ) )
          a.end = a.start + 5
          a.flag = :HonPen
          addComment( a, "mark1b EndCard" )
          #errLog( "EndCaed #{a.start}" )
        end
      end
    end
  end
  


  #
  #  提供の検出
  #
  def marking2( )

    prev = nil
    hflag = nil
    self.each do |a|
      if prev != nil and prev.flag == :HonPen
        if a.flag == nil and a.dis != nil
          if a.dis.between?( 9.6, 10.6 ) == true
            a.flag = :HonPen
            addComment( a, "mark2 offer" )
          end
        end
      end
      break if hflag == true and a.flag != :HonPen
      hflag = true if a.flag == :HonPen
      prev = a
    end
    
  end

  #
  #  半端な時間か？
  #
  def hanpa?( time )
    t = time.to_f % 10
    return false if t.between?( 0.0, 1.0 )
    return false if t.between?( 4.5, 5.5 )
    return false if t > 9.5
    return true
  end

  #
  #  データの併合をする。( n と n+1 )
  #
  def merge( list )

    list.sort.reverse.each do |n|
      self[ n ].end = self[ n+1 ].end
      self[ n+1 ].flag = :Del
    end
    calcDis()
  end
  
  #
  #  開始 15秒未満の不定 5秒以下は併合する。
  #
  def marking3()
    list = []
    self.each_with_index do |a,n|
      break if ( n + 1 ) == ( self.size - 1 )
      if self[n].flag == nil and self[n+1].flag == nil
        if self[n].dis < 5 and self[n+1].dis < 5
          list << n
        end
      end
      break if a.start > 15
    end
    if list.size > 0
      merge( list )
    end
  end
    
  #
  #  最終調整
  #
  def marking4(  )
      
    # 最後の方の半端な時間は CM とする。
    ( self.size - 2).downto( self.size - 10 ) do |n|
      a = self[n]
      if a != nil
        break if a.flag == :HonPen
        if a.flag == nil
          if hanpa?( a.dis ) == true
            a.flag = :CM
            addComment( a, "mark4a" )
          else
            break
          end
        end
      end
    end
    
    #
    #  残った未確認を確定に
    #
    n = 0
    self.each do |a|
      if a.flag == nil and a.dis != nil
        if n == 0
          a.flag = :CM
        elsif a.start > ( @lastframe * 0.95 ) or ( n > ( self.size - 4 ) )
          a.flag = :CM
        else
          a.flag = :HonPen
        end
        addComment( a, "mark4b" )
      end
      n += 1
    end
    
  end

  #
  # 終わり近くの logo付きCMを強制的に CM に
  #
  def marking1d(  )
    if ( n = self.size - 1 ) > 10
      haba = 0.5 
      n.step( n-10, -1 ) do |m|
        next if self[m].flag == nil
        if self[m].start > ( @lastframe * 0.9 )
          if self[m].flag == :HonPen
            [ 15, 30 ].each do |t|
              if self[m].dis.between?( t-haba, t+haba) == true
                self[m].flag = :CM
                addComment( self[m], "mark1d H->C" )
                break
              end
            end
            break
          end
        end
      end
    end
  end
  

  
  def getLastTime()
    self.last.mid
  end

  
  #
  # dumb データからチャプターを再構成
  #
  def createChap( fp )

    chap = Chap.new
    lasttime = getLastTime()

    flag = false
    self.each do |s|
      logo = s.flag == :HonPen ? 1 : 0
      if logo != flag
        if logo == 1
          if ( s.end - s.start ) > 5 and fp.end_of_silent == true
            time = s.end - 0.5
          else
            time = s.start + 0.5
          end
        else
          time = s.start == 0.0 ? s.start : s.end - 0.5
        end
        chap.add( time, logo )
        flag = logo
      end
    end
    chap.add( lasttime, -1 )
    chap.calcWidth()

    chap
  end

  
end



