
# 目的

本プログラムは、「PT2等 で録画した mpeg2tsファイルを H.265(HEVC) に変換しつつ同時に自動で CMカット」を Linux(Unix 系 OS) 上で実行する為のものです。

# 処理概要

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

# 実行に必要な環境

* Ubuntu 18.04.1 LTS (多分Unix系ならなんでも)
* ruby  2.5.1p57
* ruby-wave
* python 2.7.15rc1 
* Opencv 3.4.1
* ffmpeg(ffprobe) 4.0
* gimp ver.2.8.22
  (logoファイルの抽出に使用。矩形領域の切り抜きができれば何でも可)


# インストール

## ruby
```sh
$ sudo apt install ruby
$ sudo gem install wav-file
```

## python
```sh
$ sudo apt install python-dev python-numpy
```

## ffmpeg
```sh
$ sudo apt install ffmpeg
```

## opencv  
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


## 本ソフト

1. インストールするディレクトリを決める。( ~/video  )
1. そこに git-hub から
    <https://github.com/kaikoma-soft/CMcutU/archive/master.zip>
   をダウンロードして展開
1. 環境変数 PATH に上記のディレクトリを追加する。
1. const.rb の中身を自分の環境に合わせて、書き換える

   | パラメータ名| 意味                                       |
   |-------------|--------------------------------------------|
   | Top         | TSファイル等のデータを格納するディレクトリ |
   | CPU_core    | CPUのコア数                                |
   | $ffmpeg_bin | ffmpeg の実行ファイル名                    |
   | $nomalSize  | 変換後の本編画面サイズ                     |
   | $comSize    | 変換後の CM 画面サイズ                     |
   | $python_bin | python の実行ファイル名                    |

1. 入力ファイル、出力ファイル、作業用ディレクトリを作成する。  
   ( 例は、Top がそのままの場合 )
    ```sh
    % mkdir $HOME/video
    % cd $HOME/video
    % mkdir TS mp4 logo work
    ```

# ディレクトリ構造

## 入力データ( mpeg2ts ファイル )

入力の TS ファイルは、TS ディレクトリ以下に番組単位のサブディレクトリを
作りその中に置く。
```
Top
├── TS
│   ├── 番組名-1
│   │   ├── タイトル #01.ts
│   │   ├── タイトル #02.ts
│   │   └── ...
│   ├── 番組名-2
│   │   ├── タイトル #01.ts
│   │   ├── タイトル #02.ts
│   │   └── ...
│   └── ...
│       ├── ...
│       ├── ...
│       └── ...

```

## 出力ファイル(mp4ファイル)

  出力の mp4 ファイルは  Top/mp4 以下に TSディレクトリと相似したものが
  生成される。
  その際チャプター情報が入った chapList ファイルも出力される。


# 使用方法

1. 変換対象の TS ファイルを「TS/番組名」ディレクトリに置く。
1. cmcuterAll.rb を実行する。  
   この段階では、logoファイルが存在しないので、スクリーンショットと
    wav ファイルを作業ディレクトリに作っただけで、エラーで止まる。
1. logoファイルを作成する。
    1. スクリーンショットが保存されたディレクトリを指定して
      logoAnalysisSub.py を実行する。
    ```sh
    % logoAnalysisSub.py --dir work/番組名/タイトル/SS
    ```

    1. スクリーンショット画像が表示されるので、
       ロゴマークが明瞭な時点の画像を保存する。

         | キー      | 意味                                       |
         |-----------|--------------------------------------------|
         | j         | 60コマ( 30秒)飛ぶ                          |
         | k         | 60コマ( 30秒)戻る                          |
         | s         | 現在の画像を保存する。                     |
         | b         | 前のコマ( 0.5秒)に戻る                     |
         | q         | 終了                                       |
         | 上記以外  | 次のコマ( 0.5秒)に進む                     |
    1. 保存した画像の下部（白黒＋強調）部分のロゴマークを
        を gimp を使って、最小限の大きさで矩形領域の切り抜き
        (「ツール」-> 「変形ツール」-> 「切り抜き」)をする。
    1. 「画像」-> 「モード」-> 「グレイスケール」で、グレイスケール化する。
    1. logo ディレクトリの下に、画像を保存する。
1. logo-table.yaml を書き換える。  
   TS ディレクトリの下に logo-table.yaml が自動作成されているので、
   その中の logofn パラメータを、上で保存したlogo ファイル名に書き換える。
   ```
      XXXXX:
          :logofn: YYYY.png
          :cmlogofn: 
          :position: top-right
          :chapNum: 6
          :duration: 465
   ```
1. 再度 cmcuterAll.rb を実行する。  


# その他

## 実行コマンドの説明

+ cmcuterAll.rb
    - 機能  
      TS ディレクトリの tsファイルに対して解析を行い、mp4(HEVC) 変換を行う。
    - オプション

         | option | 意味                                       |
         |--------|--------------------------------------------|
         | --co   | CMカットに必要な計算のみ行う。mp4(HEVC)化の変換は行わない |

+ cmcuterChk.rb
    - 機能  
      CMカットが正しく行われたかチェックする。  
      logo-table.yaml ファイルに書かれた値と比較して、OK/NG を表示する。
      チェックするのは、mp4ファイルがあるか、チャプター数、本編の時間。

    - オプション

         | option | 意味                                          |
         |--------|-----------------------------------------------|
         | --ng   | 結果が NG な番組だけ表示する。                |
         | --sa n | 誤差の許容範囲を n 秒にする。デフォルトは 3秒 |

    - 出力例
         ```
         >>>>>  番組名 XXXXX  <<<<<<<
          ( chapNum=10, duration=1440 )
         
         No       Name    mp4 chap   duration      result
          1         01     ○   10     1440.0         OK
          2         02     ○   10     1440.0         OK
          3         03     ○   10     1440.0         OK
          4         04     ○   10     1440.0         OK
          5         05     ○   10     1440.0         OK
          6         06     ○   10     1440.0         OK
          7         07     ○   10     1440.0         OK
          8         08     ○   10     1440.0         OK
          9         09     ○   10     1440.0         OK
         10         10     ○   10     1440.0         OK
         11         11     ○   10     1440.0         OK
         12         12     ○   10     1430.0(-10)    NG
         ```


+ createFix.rb
    - 機能  
      修正ファイル( Top/TS/番組名/fix.yaml ) を対話形式で作成する。
      これにより、自動判定が間違っている場合に、強制的に 本編/CM
      を固定することが出来る。  
      修正・削除の機能は無いのでテキストエディタで行う。
      
      入力するパラメータは
      + 対象のTSファイル
      + 本編 か CM か
      + 秒数

+ logoAnalysisSub.py
    - 機能  
      logo ファイルのマッチングを行う。
      ```--dir``` オプションだけ指定された場合は、表示モードになる。
      
    - オプション

         | option      | 意味                                           |
         |-------------|------------------------------------------------|
         | --dir name  | スクリーンショットが保存された dir を指定する。|
         | --logo name | logo ファイル名を指定する。                    |

      
## 設定ファイルの説明

+ logo-table.yaml

  + 番組名単位で、下記のパラメタを設定するファイル。
    エントリーはディレクトリの有無で、自動的に作成／削除されるので、
    値を書き換える。( Top/TS/logo-table.yaml )

    | keyword   | 意味                                            |
    |-----------|-------------------------------------------------|
    |:logofn:   | 本編を認識する為の logo ファイル名。( Top/logo 以下の相対パス)|
    |:cmlogofn: | CM 判定の為の logo ファイル名（詳細は後述）     |
    |:position: | logo の画面上の位置。デフォルトは "top-right"   |
    |:chapNum:  | チャプター数                                    |
    |:duration: | 本編の時間(秒数)                                |

  + chapNum と duration は、末尾に数字 0〜9 を付けて複数記述可
  + 記述例  
      ```
      XXXXX:
          :logofn: YYYY.png
          :cmlogofn: 
          :position: top-right
          :chapNum: 6
          :chapNum1: 8
          :duration: 465
          :duration1: 495
      ```

+ fix.yaml
  + 自動判定が間違っている場合に、強制的に 本編/CM を固定する修正情報ファイル。
    ( Top/TS/番組名/fix.yaml )
  + 記述例  
      ```
      ---
      - - All
        - 1606
        - HonPen

    
+ XXXXX.chapList
   + チャプター割の計算結果が格納されたファイル。
     ( Top/mp4/番組名/タイトル.chapList)
     計算結果が間違っていた場合、このファイルを修正して再実行すると
     それに従って、再変換される。     
     

  + 例  
      ```
      0:00:00.00  CM
      0:01:36.90  HonPen
      0:04:11.92  CM
      0:06:27.37  HonPen
      0:15:07.89  CM
      0:17:22.88  HonPen
      0:29:06.88  CM
      0:30:06.00  EOF
      ```


# ノウハウ

# 既知の問題点

+ 番組宣伝の等の CM に 5秒のものがあるが、それが CM と認識されない。

