# coding: utf-8


class Ffmpeg
  
  #
  #  mpeg2ts copy
  #
  def ts2x265( opt, debug = false )
      
    arg = %W( -y )
    arg += %W( -ss #{opt[:ss]} -t #{opt[:t]} ) if opt[:ss] != nil
    arg += %W( -i #{@tsfn} )
    arg += %W( -vcodec copy -acodec copy )
    arg += %W( #{opt[:outfn]} )
    system2( "/usr/bin/ffmpeg", *arg )
  end

end
