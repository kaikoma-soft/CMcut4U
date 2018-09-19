
# 目的

本プログラムは、「PT2等 で録画した mpeg2tsファイルを H.265(HEVC) に変換しつつ同時に CMカット」を Unix 系 OS 上で実行する為のものです。

# 処理概要

CMカット単体の処理の概要は下記の通りです。

* 入力は PT2 で録画した mpeg2ts ファイル

* ffmpeg で、音声(wav)とスクリンーショット(jpeg)に分解。

* 音声ファイルを解析して、無音部分でチャプター分け。

* Opencv のテンプレートマッチを使って、jpeg にロゴマークがあるかで、
  本編／CM　を判定 (あらかじめロゴファイルは手作業で抽出しておく)

* 経験則で、チャプターを整理統合する。

* 得られたチャプター情報を元に TS をチャプター毎に mp4 に変換

* 最後に変換した mp4 ファイルを、連結して本編のみの mp4 ファイルを出力する。

これを、TSdir で指定したディレクトリ以下の .ts ファイルに対して繰り返し、
Outdir で指定したディレクトリに mp4 ファイルを出力します。

なおチャプターの継ぎ目は精度に自信がないので余裕をとり、フェードアウト、
フェードインで誤魔化しています。

##### 実行に必要な環境

* Ubuntu 18.04.1 LTS (多分Unix系ならなんでも)
* ruby  2.5.1p57
* ruby-wave
* python 2.7.15rc1 
* Opencv 3.4.1
* ffmpeg(ffprobe) 4.0
* gimp ver.2.8.22
  (logoファイルの抽出に使用。矩形領域の切り抜きができれば何でも可)


##### インストール
* ruby
```sh
$ sudo apt install ruby
$ sudo gem install wav-file
```

* python
```sh
$ sudo apt install python-dev python-numpy
```

* ffmpeg
```sh
$ sudo apt install ffmpeg
```

* opencv  
opencv は公式パッケージには無いので、opencvの 公式ページ
(<https://docs.opencv.org/master/d7/d9f/tutorial_linux_install.html>)
の手順に従ってソースからインストール。
```sh
$ sudo apt install cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
$ sudo apt install libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
$ mkdir tmp ; cd tmp
$ git clone https://github.com/opencv/opencv.git
$ git clone https://github.com/opencv/opencv_contrib.git
$ cd opencv ; mkdir build ; cd build
$ cmake -D CMAKE_BUILD_TYPE=Release -D CMAKE_INSTALL_PREFIX=/usr/local ..
$ make
$ make install
```


* 本ソフト

1. git-hub からダウンロード
1. 適当なディレクトリを作りそこに展開する。
1. const.rb の中身を自分の環境に合わせて、書き換える
1. 環境変数 PATH に上記のディレクトリを追加する。

##### 前準備

##### 使用方法

% mkdir -p $HOME/video/TS
% mkdir -p $HOME/video/mp4
% mkdir -p $HOME/video/work



##### ノウハウ

