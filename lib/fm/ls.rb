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

    def cmd_ls(argv)

        #### Parse options.

        banner = "usage: fm ls [options] <PATH>"
        options = {
            dbfile: DBFILE,
            longformat: false,
        }
        OptionParser.new do |opts|
            opts.banner = banner

            opts.on "-l", "--long", "Use a long listing format." do
                options[:longformat] = true
            end

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
        files = {}
        digestarr = []
        t0 = Time.now


        #### List the files in the path.

        h.values.each do |v0|        # Hash by file size.
            v0.values.each do |v1|   # Hash by digest.
                hasany = false
                fs = v1.select { |f| f.path =~ /^#{indexabspath}/ }
                fs.each do |f|
                    p = f.path[indexabspath.length..-1]
                    p = p.split("/")
                    if p.size > 1
                        p = p[1]
                        files[p] = true
                        hasany = true
                    end
                end

                if hasany
                    digestarr.push(v1)
                end
            end
        end


        #### Report.

        if options[:longformat]
            digestarr.each do |arr|
                if arr.size == 1
                    puts "[UNQ]: #{arr.first.path}"
                end
            end
            digestarr.each do |arr|
                if arr.size > 1
                    # FIXME: Ability to choose UN0 entry to indicate the main copy.
                    puts "[UN0]: #{arr.first.path}"
                    arr[1..-1].each do |f|
                        puts "[DUP]: #{f.path}"
                    end
                    puts
                end
            end
        else
            files.keys.each do |k|
                printf("%s\t", k)
            end
            puts
        end

        t1 = Time.now
        puts "ls completed in #{(t1-t0).round(2)}s."

    end


    module_function :cmd_ls

end
