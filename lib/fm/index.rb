# The MIT License (MIT)
#
# Copyright (c) 2015-2017 SpeedGo Computing
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


require 'digest/md5'
require 'fileutils'
require 'optparse'
require 'yaml'

require 'fm/db'
require 'fm/file'
require 'fm/match'


module FM

    def cmd_index(argv)
        #### Parse options.

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


        #### Load DB file.

        puts "Loading DB #{options[:dbfile]} ..."
        t0 = Time.now
        h = {}
        if File.exists?(options[:dbfile])
            obj = YAML::load(File.read(options[:dbfile]))
            if obj.is_a?(Hash)
                h = obj
            end
        end
        t1 = Time.now
        puts "Loaded DB in #{(t1-t0).round(2)}s."


        ####

        indexpath = argv[0]
        indexabspath = File.realpath(indexpath)
        nnewfiles = 0
        nskipfiles = 0
        ndupfiles = 0
        nfailfiles = 0
        nupdatefiles = 0
        nremovefiles = 0
        duplist = {}
        needupdate = false
        puts "Indexing #{indexpath} ..."
        t0 = Time.now


        #### Remove non-existing files and update modified files in the index path from the DB.

        dlist = []
        h.each do |skey, svalue|
            h[skey].each do |dkey, dvalue|
                h[skey][dkey].select { |s| s.path.start_with?(indexabspath) }.each do |f|
                    fsize = -1
                    digest = ""
                    fe = File.exists?(f.path)

                    if fe && File.mtime(f.path) == f.mtime
                        next
                    end

                    dlist.push(f)

                    if fe
                        nupdatefiles += 1
                        puts "[UPD]: #{f.path} #{f.digest}"
                    else
                        nremovefiles += 1
                        puts "[RMV]: #{f.path} #{f.digest}"
                    end
                end
            end
        end

        dlist.each do |f|
            h[f.fsize][f.digest].delete_if { |v| v.path == f.path }
            if h[f.fsize][f.digest].size == 0
                h[f.fsize].delete(f.digest)
                if h[f.fsize].size == 0
                    h.delete(f.fsize)
                end
            end

            needupdate = true
        end


        #### Index the path recursively.

        # FIXME: Configurable file patterns to be excluded.
        for fpath in Dir.glob("#{indexpath}/**/*", File::FNM_DOTMATCH).select { |e| e.force_encoding("binary"); File.ftype(e) == "file" && has_folder?(".git", e) == false && has_folder?(".hg", e) == false }
            begin
                fpath = File.realpath(fpath).force_encoding("binary")
                ftype = File.ftype(fpath)
                fsize = File.size(fpath)
                fmtime = File.mtime(fpath)
                # last index time.
                # storage type: raw or compressed?
                # content type: text or binary?
                # hash type.
                # hash value.

                if fsize == 0
                    nskipfiles += 1
                    puts "[SKIP]: #{fpath}"
                    next
                end

                # Lazily index the file.
                if h[fsize].nil?
                    digest = Digest::MD5.hexdigest(File.read(fpath))
                    h[fsize] = { digest => [ FMFile.new(fsize, fpath, digest, fmtime) ] }
                    needupdate = true
                    nnewfiles += 1
                    puts "[NEW]: #{fpath} #{digest}"
                else
                    # Skip if the file had been indexed.
                    is_indexed = false
                    h[fsize].values.each do |v|
                        if v.any? { |f| f.mtime == fmtime && f.path == fpath }
                            is_indexed = true
                            break
                        end
                    end
                    if is_indexed
                        next
                    end

                    digest = Digest::MD5.hexdigest(File.read(fpath))
                    if h[fsize][digest].nil?
                        h[fsize][digest] = [ FMFile.new(fsize, fpath, digest, fmtime) ]
                        needupdate = true
                        nnewfiles += 1
                        puts "[NEW]: #{fpath} #{digest}"
                    elsif h[fsize][digest].size == 1 && h[fsize][digest].first.path == fpath
                        h[fsize][digest] = [ FMFile.new(fsize, fpath, digest, fmtime) ]
                        needupdate = true
                        nupdatefiles += 1
                        puts "[UPD]: #{fpath} #{digest}"
                    else
                        ndupfiles += 1
                        if duplist[digest].nil?
                            duplist[digest] = h[fsize][digest]
                        end

                        unless h[fsize][digest].any? { |f| f.path == fpath }
                            fmfile = FMFile.new(fsize, fpath, digest, fmtime)
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


        #### Report and update DB.

        t1 = Time.now
        puts "Indexing completed in #{(t1-t0).round(2)}s."

        puts "Indexed:"
        puts "     NEW: #{nnewfiles}"
        puts "     DUP: #{ndupfiles}"
        puts "     UPD: #{nupdatefiles}"
        puts "     RMV: #{nremovefiles}"
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
