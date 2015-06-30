module FM

    class FMFile
        attr_reader :fsize
        attr_reader :digest
        attr_reader :path
        attr_accessor :mtime
        attr_accessor :itime

        def initialize(fsize, path, digest, mtime, itime = Time.now)
            @fsize = fsize
            @digest = digest
            @path = path
            @mtime = mtime
            @itime = itime      # Last index time.
        end
    end

end
