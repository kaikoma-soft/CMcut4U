#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#

override = File.dirname( $0 ) + "/override.rb"
if test( ?f, override )
  #printf("require %s\n",override)
  require override
end
