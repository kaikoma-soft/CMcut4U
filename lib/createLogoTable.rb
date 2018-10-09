#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#

#
#   
#

require 'optparse'
require 'pp'
require 'yaml'

$: << File.dirname( $0 )
require_relative '../const.rb'
  
$opt = {
  :dump => false,               # create dump data
  :restore => nil,              # read dump data
}

OptionParser.new do |opt|
  opt.on('-dump') { $opt[:dump] = true }
  opt.parse!(ARGV)
end

sdir = ENV["HOME"] + "/video/epgrec"
tdir = ENV["HOME"] + "/video/TS"
ldir = ENV["HOME"] + "/video/logo"

list = []
Dir.foreach( sdir ) do |fname|
  list << fname
end

if test( ?f, Tablefn )
  logotable = YAML.load_file( Tablefn )
end

chflag = false                  # change flag
logotable.keys.each do |dir|
  if logotable[ dir ][ :logofn ] == nil
    sname = nil
    list.each do |fname|
      if fname =~ /#{dir}.*?_(.*)\.ts/
        sname = $1
        break
      end
    end
    if sname != nil
      sname.tr!( 'ａ-ｚＡ-Ｚ','a-zA-Z')
      sname.tr!( '０-９','0-9')
      sname.sub!( /\d+$/,'')
      path = sprintf("%s/%s.png",ldir,sname)
      if test( ?f, path )
        printf("add logo %s  %s\n",dir,sname)
        logotable[ dir ][ :logofn ] = sname + ".png"
        chflag = true

        path = sprintf("%s/%s-CM.png",ldir,sname)
        if test( ?f, path )
          logotable[ dir ][ :cmlogofn ] = sname + "-CM.png"
        end
      end
    end
  end
end

if chflag == true
  File.open( Tablefn,"w") do |fp|
    fp.puts YAML.dump(logotable)
  end
end

