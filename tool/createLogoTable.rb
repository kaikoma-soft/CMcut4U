#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#

#
#   
#

require 'optparse'
require 'pp'
require 'yaml'
require 'find'

$: << File.dirname( $0 )
require_relative '../const.rb'
  
$opt = {
  :d => false,                  # debug
}

OptionParser.new do |opt|
  opt.on('-d') { $opt[:d] = true }
  opt.parse!(ARGV)
end

sdir = "/data/spool"
tdir = ENV["HOME"] + "/video/TS"
ldir = ENV["HOME"] + "/video/logo"

list = []
Find.find( sdir ) do |f|
  if f =~ /\.ts$/i
    fname = File.basename( f )
    fname.tr!( 'ａ-ｚＡ-Ｚ','a-zA-Z')
    fname.tr!( '０-９！－','0-9!-')
    list << fname
  end
end

if test( ?f, Tablefn )
  logotable = YAML.load_file( Tablefn )
end

chflag = false                  # change flag
logotable.keys.each do |dir|
  if logotable[ dir ][ :logofn ] == nil
    #pp dir if $opt[:d] == true
    sname = nil
    dir2 = dir.tr( 'ａ-ｚＡ-Ｚ','a-zA-Z').tr( '０-９！－','0-9!-')
    list.each do |fname|
      if fname =~ /#{dir2}.*?_(.*)\.ts/i
        sname = $1
        pp dir2,sname if $opt[:d] == true
        break
      end
    end
    if sname != nil
      sname.sub!( /[・\d]+$/,'')

      paths = []
      paths << sprintf("%s.png",sname)
      paths << sprintf("%s/HON.png",sname)
      paths.each do |path|
        if test( ?f, ldir + "/" + path )
          logotable[ dir ][ :logofn ] = path
          printf("add logo %s  %s\n",dir,path)
          chflag = true

          paths = []
          paths << sprintf("%s-CM.png",sname)
          paths << sprintf("%s/CM.png",sname)
          paths.each do |path|
            if test( ?f, ldir + "/" + path )
              logotable[ dir ][ :cmlogofn ] = path
              printf("add logo %s  %s\n",dir,path)
            end
          end
          break
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

