#!/usr/bin/ruby 
# -*- coding: utf-8 -*-
#
#  TSファイルの CM 部分を検出し、本編のみを mp4 に変換する。
#
#
require 'optparse'
require 'fileutils'
require 'pp'
require 'nkf'
require 'shellwords'
require 'benchmark'
require 'yaml'

$: << File.dirname( $0 )
require_relative 'cmcuter.rb'
require_relative 'cmcuterChk.rb'
require_relative 'const.rb'
require_relative 'lib/FilePara.rb'
require_relative 'lib/common.rb'
require_relative 'lib/dataClear.rb'


def usage()
  pname = File.basename($0)
    usageStr = <<"EOM"
Usage: #{pname} [Options]...

  Options:
  -f          ロックファイルが存在していても実行する。
  --co        CMカットに必要な計算のみ行う。mp4変換を行わない。
  --cm        本編画面サイズを $comSize にする。
  --ng        NG なものだけ対象にする。
  --dd n      最終・中間結果ファイルを削除する。
  --sa n　　　誤差の許容範囲を n 秒にする。デフォルトは 3秒
  --help      Show this help

#{pname} ver #{Version}
EOM
    print usageStr
    exit 1
end


OptionParser.new do |opt|
  opt.on('-v') { $opt[:v] = true } # verbose
  opt.on('-d') { $opt[:d] = true } # debug
  opt.on('-D') { $opt[:D] = true } # debug2
  opt.on('-f') { $opt[:f] = true } # force
  opt.on('--co') { |v| $opt[:calcOnly] = true  }
  opt.on('--cm') { |v| $opt[ :cmsize] = true  } # force CM size
  opt.on('--ng') { |v| $opt[:ngOnly] = true  }
  opt.on('--dd n') { |v| $opt[:delLevel] = v.to_i  } # delete data
  opt.on('--sa n') {|v| $opt[:sa] = v.to_i }         # 誤差の許容範囲
  opt.on('--help') { usage() }
  opt.parse!(ARGV)
end


#
#   多重起動防止
#
if test( ?f, LockFile )
  mtime = File.mtime( LockFile )
  now = Time.now
  if mtime > ( now - 3600 * 2)  # 2時間以内
    if $opt[:f] == false
      printf("Error: Lock file exist\n")
      exit 
    end
  end
end


#
#  終了処理
#
def exitProc()
  if test(?f, LockFile )
    File.unlink(LockFile)
  end
  exit
end


Signal.trap(:INT) do
  puts 'INT'
  exitProc()
end


$logotable = Common::loadLogoTable()


#
#  TSファイルの検索 & 実行
#
Dir.entries( TSdir ).sort.each do |dir|

  next if dir == "." or dir == ".."
  
  path1 = TSdir + "/" + dir

  if test(?d, path1 )

    # skip ファイルがある dir はスキップ
    if test( ?f, path1 + "/" + Skip ) or $logotable[ dir ][ :mp4skip ] == true
      printf("#{dir} is skip\n") if $opt[:v] == true
      next
    end
    
    Dir.entries( path1 ).sort.each do |f|

      $cmcutLog = nil
      if f =~ /\.ts$/
        ts = path1 + "/" + f
        printf("> %s\n",ts) if $opt[:v] == true

        fp = FilePara.new( ts )
        fp.setLogoTable( $logotable[ dir ], dir )

        if fp.cutSkip == true
          unless test(?f, fp.mp4fn )
            t = Benchmark.realtime { allConv( fp ) }
            errLog(sprintf("allConv() %.2f Sec\n",t))
          end
        else
          if $opt[:ngOnly] == true and test(?f, fp.chapfn ) == true
            if ( data = CmCuterChk.new.chkTitle( dir, fp ) ) != nil
              r = data.getStatus( fp.chapfn )
              if r == "NG"
                errLog( sprintf("%s is NG", ts))
                dataClear( fp, 2 )
              end
            end
          else
            dataClear( fp, $opt[:delLevel] ) 
          end

          if ! test(?f, fp.mp4fn ) or goCalc?( fp ) == true

            printf("> %s\n",ts) if $opt[:v] == false
            FileUtils.touch(LockFile)

            chap = nil
            t = Benchmark.realtime { ( chap, sdata ) = cmcutCalc( fp ) }
            errLog(sprintf("cmcutCalc() %.2f Sec\n",t))

            if $opt[:calcOnly] == false
              t = Benchmark.realtime { ts2mp4( fp, chap ) }
              errLog(sprintf("ts2mp4() %.2f Sec\n",t))
            end
          end
        end
      end
    end
  end
end



exitProc()




