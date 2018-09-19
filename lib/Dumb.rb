#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#


#
#  無音区間のデータ
#
class Dumb < Ranges

  include Common
  
  def initialize()
    super
  end
  
  def print( title )
    r = []
    r << sprintf("\n%s\n",title)
    self.each do |s|
      ss = f2min( s.start )
      ee = f2min( s.end )
      dis = s.end - s.start 
      r << sprintf("%6d (%s) - %6d (%s)  %4.1f\n", s.start,ss, s.end,ee, dis )
    end
    r
  end
  
end
