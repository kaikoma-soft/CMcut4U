#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pp'
require 'gtk2'

$: << File.dirname( $0 )
require_relative 'lib/common.rb'
require_relative 'lib/FilePara.rb'
require_relative 'lib/fixSub.rb'
require_relative 'lib/dataClear.rb'
require_relative 'lib/FixFile.rb'

# 共通パラメータ保存場所
$para = { :cb2Count => 0,
          :player   => :mpv,
        }

$opt = {
  :calcOnly => true,            # 計算のみ
  :d => true,                   # debug
  :D => false,                  # debug2
  :uc => true,                  # use cache
  :sa => 3,                     # 許容誤差
}

$mpv_opt=%w( --osd-duration=3000 --osd-level 2 --hwdec=no --window-scale=0.5 )


#
# 前準備
#
tsFiles = listTSdir()
dirs = tsFiles.keys.sort
Signal.trap( :INT ) { cleanUp(); exit() }

#
#  GUI 作成
#
window = Gtk::Window.new
window.name = "main window"

window.set_default_size(800, 600)
#window.move(20, 20)
window.signal_connect("destroy"){ cleanUp(); Gtk.main_quit  }

# vbox1
vbox1 = Gtk::VBox.new(false, 5)
window.add(vbox1)
dummy = Gtk::Label.new("")
vbox1.pack_start(dummy, false, false, 0)

#
#  TSファイル選択
# 
frame1 = Gtk::Frame.new("対象TSファイル")
vbox1.pack_start(frame1, false, false, 0)

# vbox2
vbox2 = Gtk::VBox.new(false, 5)
frame1.add(vbox2)

# dir 選択
cb1 = Gtk::ComboBox.new
n = ( dirs.size / 25 ).to_i + 1
cb1.wrap_width = n
dirs.each do |dir|
  cb1.append_text( dir)
end
vbox2.add(cb1)

# TS ファイル選択
cb2 = Gtk::ComboBox.new
vbox2.add(cb2)

cb1.signal_connect("changed") do |widget|
  dir = widget.active_text
  if tsFiles[ dir ] != nil
    $para[ :cb2Count ].times { cb2.remove_text(0) }
    n = 0
    tsFiles[ dir ].each do |file|
      cb2.append_text( file )
      n += 1
    end
    $para[ :cb2Count ] = n
  end
end

cb2.signal_connect("changed") do |widget|
  dir = cb1.active_text
  file = cb2.active_text
  if dir != nil and file != nil
    $para[ :dir ] = dir
    $para[ :tsfile ] = file
    $para[ :tspath ] = sprintf("%s/%s/%s",TSdir,dir,file)
    $para[ :sdata ] = nil
    $newFix = nil
    setExp()
  end
end

hbox2 = Gtk::HBox.new(false, 0)
vbox1.pack_start(hbox2, false, false, 10)



#
#  コマンドボタン
#
bon1 = Gtk::Button.new("計算")
hbox2.pack_start(bon1, false, false, 5)
bon1.signal_connect("clicked") do
  calc( $para, window )
end

bon2 = Gtk::Button.new("mpv 起動/終了")
hbox2.pack_start(bon2, false, true, 5)
bon2.signal_connect("clicked") do
  openMpv( $para )
end

bon3 = Gtk::Button.new("終了")
hbox2.pack_start(bon3, false, true, 5)
bon3.signal_connect("clicked") do
  cleanUp()
  window.destroy
  Gtk.main_quit
end

#
#  表
#
$style = {
  :bw => Gtk::Style.new.
           set_fg(Gtk::STATE_NORMAL, 0, 0, 0).
           set_bg(Gtk::STATE_NORMAL, 0xffff, 0xffff,0xffff),
  :br => Gtk::Style.new.
           set_fg(Gtk::STATE_NORMAL, 0, 0, 0).
           set_bg(Gtk::STATE_NORMAL, 0xffff, 0xf400,0xf400),
  :bg => Gtk::Style.new.
           set_fg(Gtk::STATE_NORMAL, 0, 0, 0).
           set_bg(Gtk::STATE_NORMAL, 0xf400, 0xffff,0xf400),
  :gg => Gtk::Style.new.
           set_fg(Gtk::STATE_NORMAL, 0xb000, 0xb000, 0xb000).
           set_bg(Gtk::STATE_NORMAL, 0xb000, 0xb000, 0xb000),
}


sw = Gtk::ScrolledWindow.new(nil, nil)
sw.shadow_type = Gtk::SHADOW_ETCHED_IN
sw.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC )
sw.set_style($style[:bw])
vbox1.add(sw)

tbl = Gtk::Table.new(2, 30, false)
tble = Gtk::EventBox.new.add(tbl)
tble.style = $style[:gg]

$para[:table] = tbl
$para[:tablee] = tble
$para[:sw] = sw
  
setTitle( tbl )

arg = [ Gtk::FILL,Gtk::FILL, 1, 1 ]
0.upto(6).each do |r|
  0.upto(30).each do |c|
    if c % 2 > 0
      style = $style[:bg]
    else
      style = $style[:br]
    end
    label = Gtk::Label.new( "" ) # sprintf("%d-%d",r,c)
    eventbox = Gtk::EventBox.new.add(label)
    eventbox.style = style
    #tbl.attach_defaults( eventbox, r, r+1, c, c+1 )
    tbl.attach( eventbox, r, r+1, c, c+1, *arg )
  end
end

sw.add_with_viewport(tble)


#
#  期待値と計算値
#
arg = [ Gtk::FILL,Gtk::FILL, 1, 1 ]
tbl = Gtk::Table.new(2, 3, true)
label = Gtk::Label.new("期待値")
tbl.attach( label, 1, 2, 0, 1, *arg )
label = Gtk::Label.new("計算値")
tbl.attach( label, 2, 3, 0, 1, *arg )
label = Gtk::Label.new("結果")
tbl.attach( label, 3, 4, 0, 1, *arg )
label = Gtk::Label.new("チャプター")
tbl.attach( label, 0, 1, 1, 2, *arg )
label = Gtk::Label.new("時間")
tbl.attach( label, 0, 1, 2, 3, *arg )
$para[:ce] = Gtk::Label.new("-") # チャプター・期待値
tbl.attach( $para[:ce], 1, 2, 1, 2, *arg )
$para[:de] = Gtk::Label.new("-") # 時間・期待値
tbl.attach( $para[:de], 1, 2, 2, 3, *arg )
$para[:cc] = Gtk::Label.new("-") # チャプター・計算値
tbl.attach( $para[:cc], 2, 3, 1, 2, *arg )
$para[:dc] = Gtk::Label.new("-") # 時間・計算値
tbl.attach( $para[:dc], 2, 3, 2, 3, *arg )
$para[:cr] = Gtk::Label.new("-") # チャプター・結果
tbl.attach( $para[:cr], 3, 4, 1, 2, *arg )
$para[:dr] = Gtk::Label.new("-") # 時間・結果
tbl.attach( $para[:dr], 3, 4, 2, 3, *arg )
vbox1.pack_start(tbl, false, false, 10)



$status_bar = Gtk::Statusbar.new
vbox1.pack_start($status_bar, false, true, 5)

window.show_all

Gtk.main

