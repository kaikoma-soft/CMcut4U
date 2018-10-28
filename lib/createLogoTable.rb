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
  :d => false,                  # debug
}

OptionParser.new do |opt|
  opt.on('-d') { $opt[:d] = true }
  opt.parse!(ARGV)
end

sdir = ENV["HOME"] + "/video/epgrec"
tdir = ENV["HOME"] + "/video/TS"
ldir = ENV["HOME"] + "/video/logo"

list = []
Dir.foreach( sdir ) do |fname|
  fname.tr!( 'ａ-ｚＡ-Ｚ','a-zA-Z')
  fname.tr!( '０-９！－','0-9!-')
  list << fname
end

if test( ?f, Tablefn )
  logotable = YAML.load_file( Tablefn )
end

chflag = false                  # change flag
logotable.keys.each do |dir|
  if logotable[ dir ][ :logofn ] == nil
    pp dir if $opt[:d] == true
    sname = nil
    list.each do |fname|
      if fname =~ /#{dir}.*?_(.*)\.ts/
        sname = $1
        pp sname if $opt[:d] == true
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

