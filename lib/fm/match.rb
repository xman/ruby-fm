module FM

    def has_folder?(folder, path)
        pos = (path =~ /^#{folder}\/|^#{folder}$|\/#{folder}\/|\/#{folder}$/)
        pos != nil
    end


    module_function :has_folder?

end
