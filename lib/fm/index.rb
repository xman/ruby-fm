require 'digest/md5'
require 'fileutils'
require 'optparse'
require 'yaml'

require 'fm/file'
require 'fm/match'


DBFILE = ENV['HOME'] + '/.fm/fdata.db'


module FM

    def cmd_index(argv)

        banner = "usage: fm index [options] <PATH>"
        options = {
            dbfile: DBFILE,
        }
        OptionParser.new do |opts|
            opts.banner = banner

            opts.on "-h", "--help", "Show this message." do
                puts opts
                exit
            end
        end.parse!(argv)

        if argv.size != 1
            $stderr << "#{banner}\n"
            exit
        end


        puts "Loading DB #{options[:dbfile]} ..."
        t0 = Time.now
        h = {}
        needupdate = true
        if File.exists?(options[:dbfile])
            obj = YAML::load(File.read(options[:dbfile]))
            if obj.is_a?(Hash)
                h = obj
                needupdate = false
            end
        end
        t1 = Time.now
        puts "Loaded DB in #{(t1-t0).round(2)}s."

        indexpath = argv[0]
        nnewfiles = 0
        nskipfiles = 0
        ndupfiles = 0
        nfailfiles = 0
        duplist = {}
        puts "Indexing #{indexpath} ..."
        t0 = Time.now

        for fpath in Dir.glob("#{indexpath}/**/*", File::FNM_DOTMATCH).select { |e| e.force_encoding("binary"); File.ftype(e) == "file" && has_folder?(".git", e) == false && has_folder?(".hg", e) == false }
            begin
                fpath = File.realpath(fpath).force_encoding("binary")
                fsize = File.size(fpath)

                if fsize == 0
                    nskipfiles += 1
                    puts "[SKIP]: #{fpath}"
                    next
                end

                # Lazy index the file.
                if h[fsize].nil?
                    h[fsize] = fpath
                    needupdate = true
                    nnewfiles += 1
                    puts "[NEW]: #{fpath} nil"
                else
                    if h[fsize].is_a?(String)
                        p = h[fsize]
                        if p == fpath
                            next
                        end

                        d = Digest::MD5.hexdigest(File.read(p))
                        h[fsize] = { d => [ FMFile.new(fsize, p, d) ] }
                        needupdate = true
                    end
                    digest = Digest::MD5.hexdigest(File.read(fpath))
                    if h[fsize][digest].nil?
                        h[fsize][digest] = [ FMFile.new(fsize, fpath, digest) ]
                        needupdate = true
                        nnewfiles += 1
                        puts "[NEW]: #{fpath} #{digest}"
                    elsif h[fsize][digest].size == 1 && h[fsize][digest].first.path == fpath
                    else
                        ndupfiles += 1
                        if duplist[digest].nil?
                            duplist[digest] = h[fsize][digest]
                        end

                        unless h[fsize][digest].any? { |f| f.path == fpath }
                            fmfile = FMFile.new(fsize, fpath, digest)
                            h[fsize][digest].push(fmfile)
                            needupdate = true
                        end
                    end
                end
            rescue StandardError => e
                nfailfiles += 1
                puts "[FAIL]: file=\"#{fpath}\" #{e.message}"
            end
        end

        duplist.values.each do |dup|
            puts "[DUP]: #{dup.first.path}"
            dup[1..-1].each do |f|
                puts "       #{f.path}"
            end
        end

        t1 = Time.now
        puts "Indexing completed in #{(t1-t0).round(2)}s."

        puts "Indexed:"
        puts "     NEW: #{nnewfiles}"
        puts "     DUP: #{ndupfiles}"
        puts "    SKIP: #{nskipfiles}"
        puts "    FAIL: #{nfailfiles}"

        if needupdate
            puts "Updating DB #{options[:dbfile]} ..."
            t0 = Time.now
            FileUtils.mkdir_p(File.dirname(options[:dbfile]))
            File.write(options[:dbfile], YAML::dump(h))
            t1 = Time.now
            puts "Updated DB in #{(t1-t0).round(2)}s."
        else
            puts "Skip updating DB."
        end

    end


    module_function :cmd_index

end
