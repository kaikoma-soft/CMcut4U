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

CPU_core  = 4
Fps       = 29.97
WavRatio  = 44100 / 10

# ScreenShot framerate
SS_rate       = 1.0 / 2
SS_frame_rate = 2

Version = "0.2.0"

#
#  for ffmpeg
#
$ffmpeg_bin = "ffmpeg"
$ffmpeg_fadetime = 0.5
$nomalSize  = "1280x720"
$comSize    = "640x360"

$python_bin = "python"
