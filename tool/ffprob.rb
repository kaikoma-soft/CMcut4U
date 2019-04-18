#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-

require 'nkf'

#
#  ffprobe の実行
#
def ffprobe( input )

  key = %w( width height codec_long_name duration field_order display_aspect_ratio )

  r = {}
  r[ :fname ] = input

  IO.popen( "ffprobe -pretty -hide_banner -show_streams \"#{input}\" 2>&1 " ) do |fp|
    fp.each_line do |line|
      line = NKF::nkf("-w",line.chomp)

      key.each do |k|
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
    if r[:duration] =~ /(\d):(\d+):(\d+)/
      r[:duration2] = $1.to_i * 3600 + $2.to_i * 60 + $3.to_i
    end
  end

  [ :duration2, :width, :height ].each do |key|
    if r[ key ] == nil
      raise "#{key.to_s} is nil #{input}"
    end
  end
  
  r

end

