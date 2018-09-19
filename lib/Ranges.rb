#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#

#
#  範囲
#
class Ranges < Array
  @@t = Struct.new(:start,      # 開始
                   :end,        # 終了
                   :data        # データ
                  )

  def initialize()
    super
  end

  def add( ts, te, d = nil )
    self << @@t.new( ts,te, d )
  end
end


