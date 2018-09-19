#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

#
#  データのクリア
#

require 'optparse'
require 'pp'
require 'benchmark'

require_relative 'common.rb'
require_relative 'FilePara.rb'

def dataClear( fp, level = 1 )

  del = []

  if level > 0
    del << fp.mp4fn
  end
  
  if level > 1
    del << fp.chapfn
  end
  
  if level > 2
    del << fp.picdir + "/" + "result.yaml"
    del << fp.picdir + "/" + "resultH.yaml"
    del << fp.picdir + "/" + "resultC.yaml"
  end
  
  if level > 3
    Dir.entries( fp.workd ).sort.each do |fn|
      if fn =~ /\.mp4/ or fn =~ /\.sh/ or fn =~ /\.txt/ or fn =~ /\.log/
        del << fp.workd + "/" + fn
      end
    end
  end
  
  if level > 4
    del << fp.wavfn
    Dir.entries( fp.picdir ).sort.each do |fn|
      if fn =~ /\.(png|jpg)/
        del << fp.picdir + "/" + fn
      end
    end
  end

  # pp del
  
  del.each do |fn|
    if test(?f,fn)
      printf("delete %s\n",fn)
      File.unlink( fn )
    end
  end
end



if File.basename($0) == "dataClear.rb"
  $: << File.dirname( $0 )

  level = 1

  OptionParser.new do |opt|
    opt.on('-d') { $opt[:d] = true }
    opt.on('-1') { level = 1 }
    opt.on('-2') { level = 2 }
    opt.on('-3') { level = 3 }
    opt.parse!(ARGV)
  end

  if ARGV.size > 0
    if test( ?f, ARGV[0] )
      fp = FilePara.new( ARGV[0] )
      dataClear( fp, level )
    end
  end

  
end

  



