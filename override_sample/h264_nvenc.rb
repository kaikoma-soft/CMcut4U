# coding: utf-8


class Ffmpeg
  
  #
  #  h264_nvenc を使用
  #
  def ts2x265( opt, debug = false )
      
    arg = %W( -y )
    arg += %W( -ss #{opt[:ss]} -t #{opt[:t]} ) if opt[:ss] != nil
    arg += %W( -i #{@tsfn} )
    if opt[:monolingual] == 1
      arg += %W( -map_channel 0.1.0  -map_channel 0.1.0 )
    elsif opt[:monolingual] == 2
      arg += %W( -ac 1 -map 0:v -map 0:1 )
    elsif opt[:monolingual] == 3
      arg += %W( -ac 1 -map 0:v -map 0:1 -map 0:10 -metadata:s:a:0 language=jpn -metadata:s:a:1 language=eng )
    end
    arg += %W( -vcodec h264_nvenc -preset fast -qp 0 -acodec aac )
    arg += %W( -movflags faststart )
    if opt[:vf] != nil or opt[:fade] != nil
      arg += %W( -vf )
      tmp = []
      tmp += opt[:vf] if opt[:vf] != nil 
      tmp << opt[:fade] if opt[:fade] != nil 
      arg << tmp.join(",")
    end
    arg += %W( -s 640x360 )
    arg += %W( #{opt[:outfn]} )
    system2( "/usr/bin/ffmpeg", *arg )
  end

end
