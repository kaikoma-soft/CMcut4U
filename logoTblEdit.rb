#!/usr/bin/ruby
# -*- coding: utf-8 -*-

#
#  logo-table.yaml の編集 GUI
#

require 'optparse'
require 'pp'
require 'gtk2'

$: << File.dirname( $0 )
require_relative 'lib/common.rb'
require_relative 'lib/FilePara.rb'
require_relative 'lib/fixSub.rb'
require_relative 'lib/dataClear.rb'
require_relative 'lib/FixFile.rb'
require_relative 'lib/logoTblEditSub.rb'

$opt = {
  :dir => nil,                     # 許容誤差
}

OptionParser.new do |opt|
  opt.on('--dir name') {|v| $opt[:dir] = v  } 
  opt.parse!(ARGV)
end


#
# 前準備
#
tsFiles = listTSdir()
$logoFiles =  listLogoDir()
dirs = tsFiles.keys.sort
Signal.trap( :INT ) { exit() }
$tblarg = [ Gtk::FILL,Gtk::FILL, 1, 1 ]
ws = {}

#
#  GUI 作成
#
window = Gtk::Window.new
window.name = "main window"

window.set_default_size(600, 300)
window.signal_connect("destroy"){ Gtk.main_quit  }

# vbox1
vbox1 = Gtk::VBox.new(false, 5)
window.add(vbox1)

tbl = Gtk::Table.new(10, 2, false)

##############
y = 0
label = Gtk::Label.new("対象ディレクトリ")
tbl.attach( label, 0, 1, y, y+1, *$tblarg )

ws[:dir] = Gtk::ComboBox.new
n = ( dirs.size / 25 ).to_i + 1
ws[:dir].wrap_width = n
dirs.each_with_index do |dir,n|
  ws[:dir].append_text( dir)
  if dir == $opt[:dir]
    ws[:dir].set_active(n)
  end
end
tbl.attach( ws[:dir], 1, 2, y, y+1, *$tblarg )

ws[:dir].signal_connect("changed") do |widget|
  dir = widget.active_text
  set_val( ws, dir )
end

##############
y = 1
hsep = Gtk::HSeparator.new
tbl.attach( hsep, 1, 2, y, y+1, *$tblarg )
label = Gtk::Label.new("")
tbl.attach( label, 0, 1, y, y+1, *$tblarg )

##############
y = 2
label = Gtk::Label.new("本編 logoファイル名")
tbl.attach( label, 0, 1, y, y+1, *$tblarg )

ws[:hlf] = Gtk::ComboBox.new
n = ( $logoFiles.size / 25 ).to_i + 1
ws[:hlf].wrap_width = n
$logoFiles.each do |dir|
  ws[:hlf].append_text( dir)
end

tbl.attach( ws[:hlf], 1, 2, y, y+1, *$tblarg )

##############
y = 3
label = Gtk::Label.new("CM logoファイル名")
tbl.attach( label, 0, 1, y, y+1, *$tblarg )

ws[:clf] = Gtk::ComboBox.new
n = ( $logoFiles.size / 25 ).to_i + 1
ws[:clf].wrap_width = n
$logoFiles.each do |dir|
  ws[:clf].append_text( dir)
end
tbl.attach( ws[:clf], 1, 2, y, y+1, *$tblarg )

##############
y = 4
label = Gtk::Label.new("logo 位置")
tbl.attach( label, 0, 1, y, y+1, *$tblarg )
hbox = Gtk::HBox.new(false, 0)
tbl.attach( hbox, 1, 2, y, y+1, *$tblarg )

ws[:lp_tl] = Gtk::RadioButton.new("左上")
ws[:lp_tl].active = true
hbox.pack_start(ws[:lp_tl], true, true, 0)
ws[:lp_tr] = Gtk::RadioButton.new(ws[:lp_tl], "右上")
hbox.pack_start(ws[:lp_tr], true, true, 0)
ws[:lp_br] = Gtk::RadioButton.new(ws[:lp_tl], "右下")
hbox.pack_start(ws[:lp_br], true, true, 0)
ws[:lp_bl] = Gtk::RadioButton.new(ws[:lp_tl], "左下")
hbox.pack_start(ws[:lp_bl], true, true, 0)

##############

y = 5
label = Gtk::Label.new("")
tbl.attach( label, 0, 1, y, y+1, *$tblarg )
label = Gtk::Label.new("チャプター数")
tbl.attach( label, 0, 1, y+1, y+2, *$tblarg )
label = Gtk::Label.new("時間(秒)")
tbl.attach( label, 0, 1, y+2, y+3, *$tblarg )

tbl2 = Gtk::Table.new(3, 10, false)
tbl.attach( tbl2, 1, 2, y, y+3, *$tblarg )

w = 60
ws[:cs] = []
ws[:dr] = []
10.times.each do |n|
  label = Gtk::Label.new("No. #{n+1}")
  tbl2.attach( label, n, n+1, 0, 1, *$tblarg )
  ws[:cs][n] = Gtk::Entry.new
  ws[:cs][n].set_size_request(w, -1)
  tbl2.attach( ws[:cs][n], n, n+1, 1, 2, *$tblarg )
  ws[:dr][n] = Gtk::Entry.new
  ws[:dr][n].set_size_request(w, -1)
  tbl2.attach( ws[:dr][n], n, n+1, 2, 3, *$tblarg )
end

##############
y = 8
label = Gtk::Label.new("オプション")
tbl.attach( label, 0, 1, y, y+1, *$tblarg )
tbl3 = Gtk::Table.new(3, 10, false)
tbl.attach( tbl3, 1, 2, y, y+1, *$tblarg )

###
y = 0
label = " このディレクトリは無視する。"
ws[:opt_id] = Gtk::CheckButton.new( label )
tbl3.attach( ws[:opt_id], 0, 2, y, y+1, *$tblarg )

###
y = 1
label = " CMカット処理は行わず、丸ごと mp4 エンコードする。"
ws[:opt_cs] = Gtk::CheckButton.new( label )
tbl3.attach( ws[:opt_cs], 0, 2, y, y+1, *$tblarg )

###
y = 2
label = " logo解析は行わず音声データのみでチャプター分割を行う"
ws[:opt_au] = Gtk::CheckButton.new( label )
tbl3.attach( ws[:opt_au], 0, 2, y, y+1, *$tblarg )

###
y = 3
label = " 長い無音期間の最後を境界にする"
ws[:opt_ls] = Gtk::CheckButton.new( label )
tbl3.attach( ws[:opt_ls], 0, 2, y, y+1, *$tblarg )

###
y = 4
label = " 本編途中にCMが無く、本編前後に長い無音期間がある"
ws[:opt_nhk] = Gtk::CheckButton.new( label )
tbl3.attach( ws[:opt_nhk], 0, 2, y, y+1, *$tblarg )


###
y = 5
label = " cmcuterChk の対象外とする"
ws[:opt_ic] = Gtk::CheckButton.new( label )
tbl3.attach( ws[:opt_ic], 0, 2, y, y+1, *$tblarg )


###
y = 6
label = " EndCard 検出を無効化"
ws[:opt_ec] = Gtk::CheckButton.new( label )
tbl3.attach( ws[:opt_ec], 0, 2, y, y+1, *$tblarg )

###
y = 7
label = " カット部分のフェードイン・アウトの処理を行わない"
ws[:opt_nf] = Gtk::CheckButton.new( label )
tbl3.attach( ws[:opt_nf], 0, 2, y, y+1, *$tblarg )

###
y = 8
label = Gtk::Label.new("２カ国語対応")
tbl3.attach( label, 0, 1, y, y+1, *$tblarg )

vbox = Gtk::VBox.new(false, 0)

ws[:opt_mono0] = Gtk::RadioButton.new("何もしない")
#button.active = true
vbox.pack_start(ws[:opt_mono0], true, true, 0)
ws[:opt_mono1] = Gtk::RadioButton.new(ws[:opt_mono0], "ステレオの左のみ残す")
vbox.pack_start(ws[:opt_mono1], true, true, 0)
ws[:opt_mono2] = Gtk::RadioButton.new(ws[:opt_mono0], "ストリーム 0 を残す")
vbox.pack_start(ws[:opt_mono2], true, true, 0)

tbl3.attach( vbox, 1, 2, y, y+1, *$tblarg )

###
y = 9
label = Gtk::Label.new("ffmpeg vopt")
tbl3.attach( label, 0, 1, y, y+1, *$tblarg )
ws[:opt_vopt] = Gtk::Entry.new
ws[:opt_vopt].set_size_request(400, -1)
tbl3.attach( ws[:opt_vopt], 1, 2, y, y+1, *$tblarg )

###
y = 10
hbox = Gtk::HBox.new( false)
label1 = Gtk::Label.new("本編の開始時間を")
label2 = Gtk::Label.new("秒遅らせる")
#tbl3.attach( label, 0, 1, y, y+1, *$tblarg )
ws[:opt_delay] = Gtk::Entry.new
ws[:opt_delay].set_size_request(50, -1)
hbox.pack_start(label1, false, false, 10)
hbox.pack_start(ws[:opt_delay], false, true, 0)
hbox.pack_start(label2, false, false, 5)
tbl3.attach( hbox, 0, 3, y, y+1 )



#
#  コマンドボタン
#
hbox = Gtk::HBox.new( true, 200 )

bon1 = Gtk::Button.new("保存")
hbox.pack_start(bon1, true, true, 20)
bon1.signal_connect("clicked") do
  dir = ws[:dir].active_text
  save( ws, dir )
end


bon3 = Gtk::Button.new("閉じる")
hbox.pack_start(bon3, true, true, 20)
bon3.signal_connect("clicked") do
  window.destroy
  Gtk.main_quit
end





#y = 8
#tbl.attach( hbox, 1, 2, y, y+1, *$tblarg )


##############

vbox1.pack_start(tbl, false, false, 10)
hsep = Gtk::HSeparator.new
vbox1.pack_start(hsep, false, true, 5)
vbox1.pack_start(hbox, false, true, 5)


if $opt[:dir] != nil
  dir = $opt[:dir]
  if ( n = dirs.index( dir )) != nil 
    ws[:dir].set_active(n)
    set_val( ws, dir )
  end
end

window.show_all

Gtk.main

