#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pp'
require 'gtk2'
require "tempfile"

require 'const.rb'
require 'lib/cmcuter.rb'
require 'lib/Chap.rb'

#
#  対象ファイルのリストアップ
#
def listTSdir()
  files = {}
  Dir.entries( TSdir ).sort.each do |dir|
    next if dir == "." or dir == ".."
    path1 = TSdir + "/" + dir
    if test(?d, path1 )
      Dir.entries( path1 ).sort.each do |fname|
        next if fname == "." or fname == ".."
        next unless fname =~ /\.ts$/
        path2 = path1 + "/" + fname
        if test(?f, path2 )
          files[dir] ||= []
          files[dir] << fname
        end
      end
    end
  end
  files
end

#
# status bar メッセージ表示
#
def statmesg( str )
  context_id = $status_bar.get_context_id("Statusbar")
  $status_bar.push(context_id, str )
end


#
# 表のタイトル表示
#
def setTitle( tbl )
  title = %w( チャプター 無音期間(秒) ←(時分秒) 間隔(秒) 種別 コメント fix)
  arg = [ Gtk::EXPAND,Gtk::FILL, 1, 1 ]
  title.each_with_index do |str,j|
    label = Gtk::Label.new( str )
#    label.set_justify(Gtk::JUSTIFY_LEFT)
#    eventbox = Gtk::EventBox.new.add(label)
    tbl.attach( label, j, j+1, 0, 1, *arg ) #, *$tblarg 
  end
end



#
#  計算結果の表
#
def calcDisp( fp, sdata, chapter )
  chap = 0
  oldtype = nil
  sdata2 = []

  # fix ファイルの読み込み
  ff = FixFile.new
  ff.readFix( fp )
  puts( ff.sprint )

  duration = 0
  sdata.each_with_index do |a,i|
    dis = a.dis != nil ? a.dis : 0.0
    tmp1 = sprintf("%.1f",a.start )
    tmp2 = sprintf("%.1f",a.end )
    tmp3 = sprintf("%.1f",a.end - a.start )
    silen = sprintf("%7s  - %7s (%4s)",tmp1,tmp2, tmp3)
    min   = sprintf("%s",Common::sec2min(a.start) )
    dis   = sprintf("%5.1f",dis )
    type  = sprintf("%-7s",a.flag == nil ? "" : a.flag.to_s)
    comme = a.comment == nil ? "" : a.comment

    if sdata[i+1] != nil
      tstart = ( a.start + a.end ) / 2
      tend   = sdata[i+1].start
      fix = ff.hantei2( a.start )
      #fix = ff.hantei( tstart,tend )
      # tmid = nil
      # if ( tend -  tstart ) < 3
      #   tmid = (( a.start + a.end ) / 2 ).round(1)
      # else
      #   tmid = (( tstart + tend ) / 2 ).round(1)
      # end
    else
      fix = FixFile::None
    end
    if oldtype != sdata[i].flag
      oldtype = sdata[i].flag
      chap += 1 
    end
    if a.flag == :HonPen
      duration += a.dis if a.dis != nil
    end
    
    sdata2 << [ chap,silen,min,dis,type,comme, fix, a.start ]
  end

  tbl = Gtk::Table.new(5, sdata.size + 1, false)
  $para[:tablee].remove( $para[:table] )
  $para[:tablee].add(tbl)
  $para[:table] = tbl

  #
  # create popup menu
  #
  menu = Gtk::Menu.new
  menuItem = []
  menuItem[0] = Gtk::MenuItem.new( ff.typeStr(0) )
  menuItem[1] = Gtk::MenuItem.new( ff.typeStr(1) )
  menuItem[2] = Gtk::MenuItem.new( ff.typeStr(2) )
  #menuItem[3] = Gtk::MenuItem.new( ff.typeStr(3) )
  #menuItem[4] = Gtk::MenuItem.new( ff.typeStr(4) )
  menuItem.each_with_index do |mi,i|
    menu.append mi
    mi.signal_connect('activate') do |widget, event|
      n = $para[:row]
      #p "select #{n} #{i}"
      $newFix[n][:label].text= ff.typeStr( i )
      $newFix[n][:type] = i
    end
  end
  menu.show_all

  # チャプターの併合数のカウント
  chapSpan = {}
  last = sdata2.last[0]
  0.step(last) do |n|
    sdata2.each_with_index do |a,i|
      if n == a[0]
        chapSpan[n] ||= {}
        if chapSpan[n][:start] == nil
          chapSpan[n][:start] = i
          chapSpan[n][:end] = i
        else
          chapSpan[n][:end] = i
        end
      end
    end
  end

  if $para[:cc] != nil
    $para[:cc].text= chapSpan.size.to_s
  end
  hon = chapter.getHonPenTime()
  if $para[:dc] != nil
    $para[:dc].text=  sprintf("%.2f",hon) # duration.round(2).to_s
  end

  if $para[:cr] != nil
    if $para[:fp] != nil
      if $para[:fp].chapNum.include?( chapSpan.size )
        $para[:cr].text= "○"
      else
        $para[:cr].text= "×"
      end
    end
  end
  if $para[:dr] != nil
    flag = false
    # hon = duration.round(2)
    $para[:fp].duration.each do |d|
      next if d == nil
      if hon.between?( d - $opt[:sa], d + $opt[:sa] ) == true
        flag = true
        break
      end
    end
    if flag == true
      $para[:dr].text= "○"
    else
      $para[:dr].text= "×"
    end
  end
  
  
  # 表の作成
  setTitle( tbl )
  #$lbw = []
  $newFix = []
  sdata2.each_with_index do |a,i|
    style = $style[:bg]
    style = $style[:br] if a[4] =~ /CM/

    a.each_with_index do |str,j|
      next if j == 7
      if j == 6
        label = Gtk::Label.new( ff.typeStr( str ))
      else
        label = Gtk::Label.new( str.to_s )
      end
      label.set_justify(Gtk::JUSTIFY_LEFT)
      eventbox = Gtk::EventBox.new.add(label)
      eventbox.style = style
      if j < 5                  # mpv seek
        eventbox.events = Gdk::Event::BUTTON_PRESS_MASK
        eventbox.signal_connect("button_press_event") {seekMpv(i)}
      elsif j == 6        # fix popup
        eventbox.events = Gdk::Event::BUTTON_PRESS_MASK
        eventbox.signal_connect("button_press_event") do |widget, event|
          $para[:row] = i
          menu.popup nil, nil, event.button, event.time
        end
        $newFix << { label: label, type: str, time: a[7] }
      end
      if j == 0
        if chapSpan[str][:start] == i
          k = i + 2 + ( chapSpan[str][:end] - chapSpan[str][:start] )
          tbl.attach( eventbox, j, j+1, i+1, k, *$tblarg )
        end
      else
        tbl.attach( eventbox, j, j+1, i+1, i+2, *$tblarg )
      end
    end
  end

  $para[:sdata] = sdata2  # 退避
  
  tbl.show_all
end




#
#  計算ボタン
#
def calc( para, parent )
  
  return if ( fn = para[:tspath] ) == nil
  if test( ?f, fn )

    if test( ?f, Tablefn )
      logotable = YAML.load_file( Tablefn )
    else
      raise "logo table file not found (#{Tablefn})"
    end
    
    fp = FilePara.new( fn )
    if fp.setLogoTable( logotable[ fp.dir ], fp.dir ) == nil
      raise
    end
    $cmcutLog = fp.cmcutLog
    $para[:fp] = fp

    if $para[:ce] != nil
      $para[:ce].text= fp.chapNum.join(",")
    end
    if $para[:de] != nil
      $para[:de].text= fp.duration.join(",")
    end
    
    #dataClear( fp, 2 )

    # ダイアログの表示
    d = Gtk::Dialog.new( nil, parent, Gtk::Dialog::MODAL)
    label = Gtk::Label.new("  ***  計算中  ***  ")
    label.show
    d.vbox.pack_start(label, true, true, 30)
    d.show_all
    statmesg( "計算中" )

    # fix が修正されていればファイルに保存
    if $newFix != nil
      $para[:sdata] != nil
      diff = false
      $para[:sdata].each_index do |i|
        diff = true if $para[:sdata][i][6] != $newFix[i][:type]
      end
      #p diff
      if diff == true
        FixFile.new.mergeFix( fp, $newFix )
        statmesg( "fix file saved" )
      end
    end
    
    t = Thread.new do           # 待機スレッド
      t.abort_on_exception = true
      ( chap, sdata ) = cmcutCalc( fp, true )
      statmesg( "計算終了" )
      d.destroy

      if sdata != nil
        calcDisp(fp, sdata, chap) # 表示
      else
        statmesg( "計算失敗" )
      end
    end
  else
    statmesg(sprintf("Error: file not found (%s)",fn))
  end
end

#
#  エンコード実行
#
def encode( para )
  return if ( fn = para[:tspath] ) == nil
  if test( ?f, fn )

    if test( ?f, Tablefn )
      logotable = YAML.load_file( Tablefn )
    else
      raise "logo table file not found (#{Tablefn})"
    end
    
    fp = FilePara.new( fn )
    fp.setLogoTable( logotable[ fp.dir ], fp.dir )
    $cmcutLog = fp.cmcutLog
    $para[:fp] = fp

    chap = Chap.new()
    chap.restore( fp.chapfn )
    
    ts2mp4( fp, chap )
  end
end


#
#  mpv 起動／終了
#
def openMpv( para )

  return if para[:tspath] == nil
  if $para[:mpfp] == nil
    fn = para[:tspath]

    fifo = nil
    Tempfile.open('mpv') do |f|
      fifo = f.path + ".fifo"
    end
    File.mkfifo( fifo )
    
    cmd = $mpv_opt + %W( --really-quiet --idle --input-file=#{fifo} ) 
    cmd << fn

    begin
      pid = spawn( "mpv", *cmd )
      t = Thread.new do           # 終了待ちスレッド
        Process::waitpid( pid )
        statmesg( "mpv end" )
        $para[:mpfp] = nil
        cleanUp()
      end
      $para[:mpfp] = File.open( fifo,"w")
      $para[:fifo] = fifo
    rescue Errno::ENOENT => e
      msg = "Error: can't exec mpv"
      statmesg( msg )
      puts( msg )
    end
  else
    mpsend("quit")
    statmesg( "mpv quit" )
    sleep 1
  end
end


def execLTE( para )
  cmd = "logoTblEdit.rb"
  arg = []
  if para[:dir] != nil
    arg = %W( --dir #{para[:dir]} )
  end
  begin
    pid = spawn( cmd, *arg )
    t = Thread.new do           # 終了待ちスレッド
      Process::waitpid( pid )
    end
  rescue Errno::ENOENT => e
    msg = "Error: can't exec #{cmd}"
    statmesg( msg )
    puts( msg )
  end
end



def execLogoAna( para )

  cmd = "logoAnalysisSub.py"
  if para[:tsfile] == nil
    msg = "Error: ts file not select"
    statmesg( msg )
    puts( msg )
    return
  end
  
  base = File.basename( para[:tsfile],".ts")
  ssdir = sprintf("%s/%s/%s/SS",Workdir, para[:dir],base  )

  if test( ?d, ssdir )
    arg = %W( --dir #{ssdir} ) 
    begin
      pid = spawn( cmd, *arg )
      t = Thread.new do           # 終了待ちスレッド
        Process::waitpid( pid )
      end
    rescue Errno::ENOENT => e
      msg = "Error: can't exec #{cmd}"
      statmesg( msg )
      puts( msg )
    end
  else
    msg = "Error: screen shot dir not found : #{ssdir}"
    statmesg( msg )
    puts( msg )
  end
end



#
# fifo の後始末
#
def cleanUp()
  if $para[:fifo] != nil
    if FileTest.pipe?( $para[:fifo] )
      #pp "unlink #{$para[:fifo]}"
      File.unlink( $para[:fifo] )
    end
    $para[:fifo] = nil
  end
end
  



#
#  mpv にコマンド送信
#
def mpsend( cmd )
  if $para[:mpfp] != nil
    #puts( cmd )
    $para[:mpfp].puts( cmd )
    $para[:mpfp].flush
  else
    statmesg( "Error: mpv not exec" )
  end
end

#
#  
#
def seekMpv( n )
  #puts("seekMlayer(#{n})")
  
  if $para[:sdata] != nil
    sec = $para[:sdata][n][1].split[0].to_f - 1
    sec = 0 if sec < 0
    statmesg("seek #{sec.to_i} sec"  )
    mpsend("seek #{sec.to_i} absolute\n")
  end
  
end
