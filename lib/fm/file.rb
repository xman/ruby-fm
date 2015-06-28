module FM

    class FMFile
        attr_reader :fsize
        attr_reader :digest
        attr_reader :path

        def initialize(fsize, path, digest)
            @fsize = fsize
            @digest = digest
            @path = path
        end
    end

end
