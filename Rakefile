#namespace :test do
#  file "dsss.conf"  
#end

SENDERO_SRC = "sendero/**/*.d"
SENDERO_BASE_SRC = "base/sendero_base/**/*.d"
TEST_SENDERO = "test_sendero.d"

SRC = FileList[SENDERO_SRC, SENDERO_BASE_SRC, TEST_SENDERO]

TEST_FILES = FileList["test/template/*.xml"]

file "test_sendero.exe" => SRC do
  sh "dsss build test_sendero.d"
end

task :build => "test_sendero.exe"

task :test_files => TEST_FILES

task :test => [:build, :test_files] do
  sh "test_sendero"
end

task :default => [:test]