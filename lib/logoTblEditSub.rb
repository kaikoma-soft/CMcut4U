#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pp'
require 'gtk2'
require "tempfile"
require 'find'

require 'const.rb'
require 'lib/cmcuter.rb'
require 'lib/common.rb'

#
#  logoファイルのリストアップ
#
def listLogoDir()
  files = [ "" ]
  Find.find( LogoDir ) do |f|
    if f =~ /\.(jpg|png|gif)$/
      fname = File.basename( f )
      next if fname =~ /^logo-\d+\.png/
      fname = f.sub(/#{LogoDir}/,'')
      fname.sub!(/^\//,'')
      files << fname
    end
  end
  files
end





#
#   読み込む & 設定
#
def set_val( ws, dir = nil )
  
  # 空の状態に初期化
  ws[:hlf].set_active(-1)
  ws[:clf].set_active(-1)
  ws[:lp_tr].active = true
  10.times.each do |n|
    ws[:cs][n].set_text("")
    ws[:dr][n].set_text("")
  end
  ws[:opt_id].active=(false)
  ws[:opt_cs].active=(false)
  ws[:opt_au].active=(false)
  ws[:opt_ls].active=(false)
  ws[:opt_nhk].active=(false)
  ws[:opt_ic].active=(false)
  ws[:opt_ec].active=(false)
  ws[:opt_nf].active=(false)
  ws[:opt_mono0].active = true
  ws[:opt_vopt].set_text("")
  ws[:opt_odelay].set_text("")
  ws[:opt_cdelay].set_text("")

  # 値をセット
  if test( ?f, Tablefn )
    logotable = YAML.load_file( Tablefn )
  else
    raise "logo table file not found (#{Tablefn})"
  end

  lt = logotable[ dir ] 
  if lt != nil    
    if lt[:logofn] != nil
      if ( n = $logoFiles.index( lt[:logofn] )) != nil 
        ws[:hlf].set_active(n)
      end
    end
    if lt[:cmlogofn] != nil
      if ( n = $logoFiles.index( lt[:cmlogofn] )) != nil 
        ws[:clf].set_active(n)
      end
    end
    if lt[:position] != nil
      case lt[:position]
      when "top-right"    then ws[:lp_tr].active = true
      when "top-left"     then ws[:lp_tl].active = true
      when "bottom-left"  then ws[:lp_bl].active = true
      when "bottom-right" then ws[:lp_br].active = true
      end
    end
    chap = []
    ([:chapNum] + 0.upto(9).map{ |n| "chapNum#{n}".to_sym }).each do |sym|
      chap << lt[sym] if lt[sym] != nil
    end
    chap.sort.each_with_index do |v,n|
      ws[:cs][n].set_text(v.to_s)
    end

    duration = []
    ([:duration] + 0.upto(9).map{ |n| "duration#{n}".to_sym }).each do |sym|
      duration << lt[sym] if lt[sym] != nil
    end
    duration.sort.each_with_index do |v,n|
      ws[:dr][n].set_text(v.to_s)
    end

    if lt[ :ignore_dir ] != nil
      ws[:opt_id].active=(true)
    end

    if lt[ :cmcut_skip ] != nil
      ws[:opt_cs].active=(true)
    end

    if lt[ :audio_only ] != nil
      ws[:opt_au].active=(true)
    end
    if lt[ :ffmpeg_vfopt ] != nil
      ws[:opt_vopt].set_text(lt[ :ffmpeg_vfopt ])
    end
    
    if lt[ :fade_inout ] != nil
      ws[:opt_nf].active=(true)
    end
    
    if lt[ :end_of_silent ] != nil
      ws[:opt_ls].active=(true)
    end

    if lt[ :nhk_type ] != nil
      ws[:opt_nhk].active=(true)
    end
    
    if lt[ :ignore_check ] != nil
      ws[:opt_ic].active=(true)
    end
    if lt[ :ignore_endcard ] != nil
      ws[:opt_ec].active=(true)
    end

    if lt[ :monolingual ] != nil
      case lt[ :monolingual ].to_i
      when 1 then ws[:opt_mono1].active = true
      when 2 then ws[:opt_mono2].active = true
      end
    end

    if lt[ :opening_delay ] != nil
      ws[:opt_odelay].set_text(lt[ :opening_delay ].to_s)
    end
    
    if lt[ :closeing_delay ] != nil
      ws[:opt_cdelay].set_text(lt[ :closeing_delay ].to_s)
    end
    
  end
end
  
#
#   保存
#
def save( ws, dir )

  return if dir == nil
  
  lt = Common::loadLogoTable()
  lt[ dir ] = {}
  r = lt[ dir ]
  
  r[:logofn]   = ws[:hlf].active_text
  r[:cmlogofn] = ws[:clf].active_text
  if ws[:lp_tr].active?
    r[:position] = "top-right"
  elsif  ws[:lp_tl].active?
    r[:position] = "top-left" 
  elsif ws[:lp_bl].active?
    r[:position] = "bottom-left"  
  elsif ws[:lp_br].active?
    r[:position] = "bottom-right"
  end

  cs = []
  dr = []
  10.times.each do |n|
    tmp = ws[:cs][n].text.strip.to_i
    cs << tmp if tmp != nil and tmp > 0
    tmp = ws[:dr][n].text.strip.to_i
    dr << tmp if tmp != nil and tmp > 0
  end
  cs.sort.each_with_index do |v,n|
    r[ "chapNum#{n}".to_sym ] = v
  end
  dr.sort.each_with_index do |v,n|
    r[ "duration#{n}".to_sym ] = v
  end

  if ws[:opt_id].active?
    r[ :mp4skip ] = true
  end

  if ws[:opt_cs].active?
    r[ :cmcut_skip ] = true
  end

  if ws[:opt_au].active?
    r[ :audio_only ] = true
  end

  if ws[:opt_ls].active?
    r[ :end_of_silent ] = true
  end

  if ws[:opt_nhk].active?
    r[ :nhk_type ] = true
  end
  
  if ws[:opt_ic].active?
    r[ :ignore_check ] = true
  end

  if ws[:opt_ec].active?
    r[ :ignore_endcard ] = true 
  end

  if ws[:opt_nf].active?
    r[ :fade_inout ] = true 
  end

  if ws[:opt_mono1].active?
    r[ :monolingual ] = 1
  elsif ws[:opt_mono2].active?
    r[ :monolingual ] = 2
  end

  tmp = ws[:opt_vopt].text
  if tmp != nil and tmp != ""
    r[ :ffmpeg_vfopt ] = tmp
  end

  tmp = ws[:opt_odelay].text
  if tmp != nil and tmp != ""
    r[ :opening_delay ] = tmp.to_f
  end

  tmp = ws[:opt_cdelay].text
  if tmp != nil and tmp != ""
    r[ :closeing_delay ] = tmp.to_f
  end

  Common::saveLogoTable( lt )

end

