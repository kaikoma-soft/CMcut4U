#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'optparse'
require 'pp'

$: << File.dirname( $0 )
require_relative 'lib/common.rb'
require_relative 'lib/FilePara.rb'


def selectBaseDir( )

  dirs = []
  Dir.entries( TSdir ).sort.each do |fn|
    next if fn == "." or fn == ".."
    path = TSdir + "/" + fn
    if test( ?d, path )
      dirs << fn
    end
  end

  if dirs.size == 0
    printf("dir not found in %s\n",TSdir)
    return
  end
  
  begin
    n = 1
    dirs.each do |fn|
      printf(" %2d: %s\n",n, fn)
      n += 1
    end
    printf("対象ディレクトリは？ ")
    ans = STDIN.gets.chomp
    ansi = ans.to_i
    if ansi < 1 or ansi > dirs.size
      puts("Error: 再度入力して下さい。")
      raise
    end
  rescue
    retry
  end

  createFix( TSdir + "/" + dirs[ansi - 1] )
end

def createFix( dir)

  fixfn = dir + "/fix.yaml"
  fix = []
  if test( ?f, fixfn )
    fix = YAML.load_file( fixfn  )
    if fix != nil
      puts("-" * 10 + "  now  " + "-" * 10 )
      fix.each do |tmp|
        pp tmp
      end
      puts("-" * 27 )
    end
  end

  tss = []
  Dir.entries( dir ).sort.each do |fn|
    if fn =~ /\.ts$/
      tss << fn
    end
  end
  if tss.size == 0
    printf("TS file not found\n")
    return
  end

  begin
    printf("  0: all\n")
    n = 1
    tss.each do |fn|
      printf(" %2d: %s\n",n, fn)
      n += 1
    end
    printf("対象ファイルは？ ")
    ans = STDIN.gets.chomp
    ansi = ans.to_i
    if ans == "0"
      fn = "all"
    elsif ansi > 0 and ansi <= tss.size
      fn = tss[ ansi - 1 ]
    else
      puts("Error: 再度入力して下さい。")
      raise
    end
  rescue
    retry
  end

  begin
    printf("\n本編(h) or CM(c)？ ")
    ans = STDIN.gets.chomp
    if ans == "c"
      type = "CM"
    elsif ans == "h"
      type = "HonPen"
    else
      puts("Error: 再度入力して下さい。")
      raise
    end
  rescue
    retry
  end

  begin
    printf("\n秒数を入力して下さい。 ")
    ans = STDIN.gets.chomp.to_i
    if ans > 0
      time = ans
    else
      puts("Error: 再度入力して下さい。")
      raise
    end
  rescue
    retry
  end

  fix << [ fn, time, type ]

  File.open( fixfn,"w") do |fp|
    fp.puts YAML.dump( fix )
  end
  
end

  
OptionParser.new do |opt|
  opt.banner = 'Usage: createFix [ dir1 dir2 ...]'
  opt.parse!(ARGV)
end

if ARGV.size > 0
  ARGV.each do |dir|
    if test( ?d, dir )
      createFix( dir )
    end
  end
else
  selectBaseDir( )
end


