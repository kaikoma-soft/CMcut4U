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

OptionParser.new do |opt|
  opt.on('-v') { $opt[:v] = true } # verbose
  opt.on('-d') { $opt[:d] = true }
  opt.on('-D') { $opt[:D] = true }
  opt.on('-f') { $opt[:f] = true } # force
  opt.on('--co') { |v| $opt[:calcOnly] = true  }
  opt.on('--ng') { |v| $opt[:ngOnly] = true  }
  opt.on('--dd n') { |v| $opt[:delLevel] = v.to_i  } # delete data
  opt.on('-n n') { |v| $opt[:limit] = v.to_i - 1 }      # limit num
  opt.parse!(ARGV)
end


#
#   多重起動防止
#
if test( ?f, LockFile )
  mtime = File.mtime( LockFile )
  now = Time.now
  if mtime > ( now - 3600 * 2)  # 2時間以内
    printf("Error: Lock file exist\n")
    exit if $opt[:f] == false
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
count = 1
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

        go = false

        if $opt[:ngOnly] == true and test(?f, fp.chapfn ) == true

          if ( data = CmCuterChk.new.chkTitle( dir, fp ) ) != nil
            r = data.getStatus( fp.chapfn )
            if r == "NG"
              go = true
              errLog( sprintf("%s is NG", ts))
              dataClear( fp, 2 )
            end
          end
        else
          dataClear( fp, $opt[:delLevel] ) 
        end

        if test(?f, fp.mp4fn ) and test(?f, fp.chapfn )
          if File.mtime( fp.mp4fn ) < File.mtime( fp.chapfn )
            go = true
          end
        else
          go = true
        end
        
        if go == true
          printf("> %s\n",ts) if $opt[:v] == false
          FileUtils.touch(LockFile)

          t = Benchmark.realtime { cmcuter( fp ) }
          errLog(sprintf("cmcuter() %.2f Sec\n",t))

          if $opt[:limit] != nil
            if $opt[:limit] < count
              printf("count linit %d\n",count )
              exitProc()
            end
          end
          count += 1
        end
      end
    end
  end
end



exitProc()




