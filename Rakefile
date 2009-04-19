# encoding: UTF-8

require "rake/testtask"
require "rake/rdoctask"

task :default => :test

Rake::TestTask.new do |test|
  test.libs       << "test"
  test.test_files =  FileList["test/test_*.rb"]
  test.warning    =  true
  test.verbose    =  true
end

Rake::RDocTask.new do |rdoc|
	rdoc.title    = "Mungr Documentation"
	rdoc.main     = "README"
	rdoc.rdoc_dir = "doc"
	rdoc.rdoc_files.include(*%w[README lib/])
end
