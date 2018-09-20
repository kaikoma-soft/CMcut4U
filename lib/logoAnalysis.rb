#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

#
#  opencv用の python を実行して、その結果を受け取る。
#
require 'benchmark'
require 'yaml'

require_relative 'common.rb'
require_relative 'Chap.rb'
require_relative 'FilePara.rb'

def logoAnalysis( fp, picdir )

  chapH = nil
  chapC = nil
  dbfnH = "#{picdir}/resultH.yaml"
  dbfnC = "#{picdir}/resultC.yaml"

  errLog("logoAnalysis() start")
  
  if $opt[:uc] == true
    if test(?f,dbfnH ) == true
      chapH = YAML.load_file( dbfnH )
    end
    if test(?f,dbfnC ) == true
      chapC = YAML.load_file( dbfnC )
      chapC.setcmDataFlag() if chapC != nil
    end
    if chapH != nil
      return [ chapH, chapC ]
    end
  end
  
  threads = []
  chh = chc = 0
  mesg = []
  # 番組ロゴの検出
  threads << Thread.new do
    t = Benchmark.realtime {( chapH, mesg ) = runOpencv( fp.logofn, picdir )}
    errLog(sprintf( "%s %.2f Sec\n",mesg.join(),t))
  end
  waitThreads( threads )

  # CMロゴの検出
  if fp.cmlogofn != nil and fp.cmlogofn.size > 0
    threads << Thread.new do
      t = Benchmark.realtime{( chapC, mesg ) = runOpencv(fp.cmlogofn, picdir)} 
      errLog(sprintf( "%s %.2f Sec\n",mesg.join(),t))
      chapC.setcmDataFlag() if chapC != nil
    end
  end
  threads.each {|t| t.join}
    
  if chapH != nil
    File.open( dbfnH,"w") do |f|
      f.puts YAML.dump(chapH)
    end
  end
  if chapC != nil
    File.open( dbfnC,"w") do |f|
      f.puts YAML.dump(chapC)
    end
  end
  
  return [ chapH, chapC ]
end


def runOpencv( logofns, picdir )
  now = nil
  dir = File.dirname( $0 )
  chap = Chap.new

  chap.add( 0, 0 )  # 最初
  last = nil
  old = 0
  mesg = []

  arg = %W( #{dir}/logoAnalysisSub.py --dir #{picdir} )
  logofns.each {|logofn| arg += [ "--logo", logofn ] }

  IO.popen( [ $python_bin, *arg ],"r" ) do |fp|
    fp.each_line do |line|
      if line =~ /^\#/
        mesg << line
      elsif line =~ /^ss_(\d+)\.(png|jpg)\s+[\d\.]+\s+(\d)/
        fn = ( $1.to_f )    
        logo = $3.to_i
        now = ( fn * SS_rate ) - 1 # -1 はオフセット

        if now > 0
          if old != logo
            # printf("%7.1f %d\n", now, logo )
            chap.add( now, logo )
            old = logo
          end
        end
        last = now
      end
    end
  end

  chap.add( last, -1 )  # 最終
  chap.calcWidth()
  chap.delmin()

  [ chap, mesg ]
end




#
#
#
if File.basename($0) == "logoAnalysis.rb"
  $: << File.dirname( $0 )
  
  fp = FilePara.new( "" )
  picdir = nil
  
  OptionParser.new do |opt|
    opt.on('-1 fn') {|v| fp.logofn = v }
    opt.on('-2 fn') {|v| fp.cmlogofn = v }
    opt.on('--dir dir') {|v| picdir = v }
    opt.on('-d') {$opt[:d] == true }
    opt.parse!(ARGV)
  end

  ( chapH, chapC ) = logoAnalysis( fp, picdir )

  puts chapH.sprint("### HonPen Chapter from logo data")
  if chapC != nil 
    puts chapC.sprint("### CM Chapter from logo data")
  end
  #puts YAML.dump(data)

  
end

