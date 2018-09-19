#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-
#

#
#   
#

require 'optparse'
require 'pp'
require 'yaml'

require 'const.rb'
  
$opt = {
  :dump => false,               # create dump data
  :restore => nil,              # read dump data
}

OptionParser.new do |opt|
  opt.on('-dump') { $opt[:dump] = true }
  opt.parse!(ARGV)
end

sdir = ENV["HOME"] + "/video/fromEst"
tdir = ENV["HOME"] + "/video/TS"


list = {}
Dir.foreach( sdir ) do |fname|

  [ 
    /・181/,
    /NHK総合1・甲府/,
    /\s+アニメ/,
    /＜アニメギルド＞/,
    /＜ノイタミナ＞/,
  ].each do |pat|
    fname.gsub!(pat,'')
  end
  fname.gsub!(/(\S)(第)/, '\1 \2')
  fname.gsub!(/(\S)(\#)/, '\1 \2')
  fname.gsub!(/▼/," " )
  
  if fname =~ /^\d+\s(.*?)\s.*\s(.*?)\.ts$/
    t=$1
    b=$2
    #printf("%-40s %s\n",t,b )
    list[t] = b
  end
    
end

#pp list

data = {}
Dir.foreach( tdir ) do |fname|
  next if fname == "." or fname == ".."
  path = tdir + "/" + fname
  if test( ?d, path )
    logo = list[fname] != nil ? list[fname] : "?"
    #printf("%-30s %s\n",fname, logo)
    data[ fname ] = {
      logofn:   logo + ".png",
      cmlogofn: logo + "-CM.png",
      position: "top-left",
      calcOnly: true,
      chapNum:  10,
      duration: 1440,
    }
    
  end
end

File.open( Tablefn,"w") do |fp|
  fp.puts YAML.dump(data)
end
