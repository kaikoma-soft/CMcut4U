
## 名前

containerConv.rb - mpeg2ts のコンテナの変換を行う

## 書式

containerConv.rb [オプション] TSファイル

## 説明

まれに録画した TS ファイルが mpv でシーク出来ない場合がある。
その時にコンテナを変換をすると、シークが出来るようになる。

- --mp4

   mp4コンテナに変換する。 出力ファイルの拡張子は ```.mp4```
- --ps

   PSコンテナに変換する。 出力ファイルの拡張子は、```.ps```
- --link

    元ファイルをリネームして、変換したファイルにシンボリックリンクを張る。



## 実行例

```
%ls -l
-rw-rw-r-- 1 bar bar 119772544  4月 29 19:33 foo.ts

% containerConv.rb --mp4 --link foo.ts

% ls -l
-rw-rw-r-- 1 bar bar 115294104  4月 29 19:33 foo.mp4
lrwxrwxrwx 1 bar bar         7  4月 29 19:33 foo.ts -> foo.mp4
-rw-rw-r-- 1 bar bar 119772544  4月 29 19:33 foo.ts.org

```
