require "bundler/gem_tasks"
require 'rake/testtask'


task :default => []


desc ''
task :test
Rake::TestTask.new do |t|
    t.libs << 'lib'
    t.test_files = Dir.glob('test/**/test_*.rb')
end
