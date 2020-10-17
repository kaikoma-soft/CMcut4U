
## お知らせ

本ソフトウエアは、開発中止とします。
後継は、改良版である
[CMcut4U2](https://github.com/kaikoma-soft/CMcut4U-Mk2) です。


## 背景

従来 Unix系OS 上で 自動CMカットを行おうとすると comskip
ぐらいしか選択肢が無かった。
しかし comskip は精度が悪かったり、
誤判定した時のリカバリが面倒だったりしたので、
自作することにしました。


## 目的

本プログラムは、「PT2等で録画した mpeg2tsファイルを H.265(HEVC) に変換しつつ同時に自動で CMカットを Linux(Unix 系 OS) 上で実行する」為のものです。


## 特徴

* ロゴファイルを用意しておけば、ほぼ全自動で CM カットして H.265(HEVC)
  に変換出来る。
* 分割したチャプター数、時間を期待値と比較して結果を表示。
* 期待値と異なった場合は、GUI で修正パラメータを入力してリトライ出来る。


## 処理概要

CMカット単体の処理の概要は下記の通りです。

* 入力は PT2 で録画した mpeg2ts ファイル
* TSファイルを ffmpeg で、音声(wav)とスクリンーショット(jpeg)に分解。
* 音声ファイルを解析して、無音部分でチャプター分け。
* Opencv のテンプレートマッチを使って、jpeg にロゴマークがあるかで、
  本編／CM  を判定 (あらかじめロゴファイルは手作業で抽出しておく)
* 経験則で、チャプターを整理統合する。
* 得られたチャプター情報を元に TS をチャプター毎に mp4 に変換
* 最後に変換した mp4 ファイルを、連結して本編のみの mp4 ファイルを出力する。

これを、TSdir で指定したディレクトリ以下の .ts ファイルに対して繰り返し、
Outdir で指定したディレクトリに mp4 ファイルを出力します。

なおチャプターの継ぎ目は精度に自信がないので余裕をとり、フェードアウト、
フェードインで誤魔化しています。


## 実行に必要な環境

* Ubuntu 18.04.1 LTS (多分Unix系ならなんでも)
* ruby  2.5.1p57
* ruby-gtk2 3.2.4
* ruby-wave
* python 2.7.15rc1 
* Opencv 3.4.1
* ffmpeg(ffprobe) 4.0
* mpv 0.27.2
* gimp ver.2.8.22
  (logoファイルの抽出に使用。矩形領域の切り抜きができれば何でも可)
* X window (fixGUI.rb の実行に必要)


## ライセンス
このソフトウェアは、Apache License Version 2.0 ライセンスのも
とで公開します。詳しくは LICENSE を見て下さい。



詳細は、
[作者 WEB ページ](https://kaikoma-soft.github.io/src/CMcut4U.html)
を参照して下さい。

+ [インストール](http://www.asahi-net.or.jp/~sy8y-siy/CMcut_on_Unix/#インストール)

+ [ディレクトリ構造](http://www.asahi-net.or.jp/~sy8y-siy/CMcut_on_Unix/#ディレクトリ構造)

+ [使用方法](http://www.asahi-net.or.jp/~sy8y-siy/CMcut_on_Unix/#使用方法)

+ [実行コマンドの説明](http://www.asahi-net.or.jp/~sy8y-siy/CMcut_on_Unix/#実行コマンドの説明)
      
+ [設定ファイルの説明](http://www.asahi-net.or.jp/~sy8y-siy/CMcut_on_Unix/#設定ファイルの説明)

+ [性能](http://www.asahi-net.or.jp/~sy8y-siy/CMcut_on_Unix/#性能)

+ [既知の問題点](http://www.asahi-net.or.jp/~sy8y-siy/CMcut_on_Unix/#既知の問題点)

