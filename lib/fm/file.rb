module FM

    class FMFile
        attr_reader :fsize
        attr_reader :digest
        attr_reader :path
        attr_accessor :mtime

        def initialize(fsize, path, digest, mtime)
            @fsize = fsize
            @digest = digest
            @path = path
            @mtime = mtime
        end
    end

end
