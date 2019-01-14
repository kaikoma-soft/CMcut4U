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
require_relative 'lib/cmcuter.rb'
require_relative 'cmcuterChk.rb'
require_relative 'const.rb'
require_relative 'lib/FilePara.rb'
require_relative 'lib/common.rb'
require_relative 'lib/dataClear.rb'

require_relative 'lib/opt.rb'


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
  if $opt[:dir] != nil
    next if $opt[:dir] != dir
  end
  
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

            if $opt[:calcOnly] == false and chap != nil
              t = Benchmark.realtime { ts2mp4( fp, chap ) }
              errLog(sprintf("ts2mp4() %.2f Sec\n",t))
            end
          end
        end
      end
    end
  end
end

#
#  autoremove
#
if $opt[:autoremove] == true
  Dir.entries( Workdir ).sort.each do |dir1|
    next if dir1 == "." or dir1 == ".."
    path1 = Workdir + "/" + dir1
    if test( ?d, path1 )
      Dir.entries( path1 ).sort.each do |dir2|
        next if dir2 == "." or dir2 == ".."
        path2 = path1 + "/" + dir2
        if test( ?d, path2 )
          ts = sprintf("%s/%s/%s.ts",TSdir,dir1,dir2)
          if test( ?f, ts )
            printf("+ %s\n",ts) if $opt[:d] == true
          else
            printf("work del %s/%s\n",dir1,dir2 )
            FileUtils.rmtree( path2 )
          end
        end
      end
    end
  end

  # 空になったディレクトリを削除
  Dir.entries( Workdir ).sort.each do |dir1|
    next if dir1 == "." or dir1 == ".."
    path1 = Workdir + "/" + dir1
    if test( ?d, path1 )
      n = Dir.entries( path1 ).size
      if n == 2 
        printf("del %s\n", dir1 )
        FileUtils.rmdir( path1 )
      end
    end
  end
end




exitProc()




