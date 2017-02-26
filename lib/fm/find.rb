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

    def cmd_find(argv)

        #### Parse options.

        banner = "usage: fm find [options] <PATH>"
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
        earr = []   # List of files exists in DB.
        nearr = []  # List of files not exists in DB.
        nfailfiles = 0
        t0 = Time.now


        #### Find files in the path recursively.

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
                digest = Digest::MD5.hexdigest(File.read(fpath))
                fmfile = FMFile.new(fsize, fpath, digest, fmtime)

                if h[fsize] && h[fsize][digest]
                    earr.push(fmfile)
                else
                    nearr.push(fmfile)
                end

            rescue StandardError => e
                nfailfiles += 1
                puts "[FAIL]: file=\"#{fpath}\" #{e.message}"
            end
        end


        #### Report.

        nearr.sort! { |a,b| a.path <=> b.path }

        puts "Number of files found: #{earr.size}"

        puts "Number of files not found: #{nearr.size}"
        nearr.each do |f|
            puts "    #{f.path}"
        end

        t1 = Time.now
        puts "Find completed in #{(t1-t0).round(2)}s."

    end


    module_function :cmd_find

end
