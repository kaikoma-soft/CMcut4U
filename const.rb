#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
#

#
#   定数定義
#
Top       = ENV["HOME"] + "/video"
TSdir     = Top + "/TS"
Outdir    = Top + "/mp4"
Workdir   = Top + "/work"
LockFile  = Top + "/work/.lock"
LogoDir   = Top + "/logo"
Tablefn   = TSdir + "/logo-table.yaml"
Skip      = "mp4.skip"
CmcutSkip = "cmcut.skip"
LongSilenceTime = 2.9

CPU_core  = 8
$max_threads = (CPU_core * 1.0 ).to_i

Fps       = 29.97
WavRatio  = 44100 / 10

# ScreenShot framerate
SS_rate       = 1.0 / 2
SS_frame_rate = 2

Version = "0.8.1"

#
#  for ffmpeg
#
$ffmpeg_bin      = "/usr/local/bin/ffmpeg"
$ffmpeg_fadetime = 0.5
$nomalSize       = "1280x720"
$cmSize          = "640x360"

$python_bin      = "python"

#0 240  1680  1920
#1080
