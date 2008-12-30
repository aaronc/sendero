#namespace :test do
#  file "dsss.conf"  
#end

import '../decorated_d/build/Parser.rake'

SENDERO_SRC = "sendero/**/*.d"
SENDERO_BASE_SRC = "base/sendero_base/**/*.d"
TEST_SENDERO = "test_sendero.d"
TEST_SERVER = "test_server.d"
RAGEL_SRC = FileList["sendero/**/*.rl"];
RAGEL_OUTPUT = RAGEL_SRC.ext(".d");
APD_SRC = FileList['sendero/xml/xpath10/*.apd']
SCRIPTS_SRC = FileList["scripts/**/*.d"]

SENDEROXC_SRC = FileList["senderoxc/**/*.d", "../decorated_d/decorated_d/**/*.d", '../decorated_d/decorated_d/parser/Parser.d']

rule ".d" => ".rl" do |f|
  sh "ragel -D -o #{f.name} #{f.source}"
end

file 'sendero/xml/xpath10/Parser.d' => APD_SRC do
  Dir.chdir("sendero/xml/xpath10") {
    sh "apaged_0.4.2", "Parser.apd", "Parser.d"
  }
end

SRC = FileList[SENDERO_SRC, SENDERO_BASE_SRC, 'sendero/xml/xpath10/Parser.d', TEST_SENDERO, TEST_SERVER, RAGEL_OUTPUT]

TEST_FILES = FileList["test/template/*.xml"]

file "test_sendero.exe" => SRC do
  sh "dsss build test_sendero.d"
end

file "test_server.exe" => SRC do
  sh "dsss build test_server.d"
#  sh "objdump test_server -t > test_server.symbols"
end

file "test_server_client.exe" => SRC do
  sh "dsss build test_server_client.d"
end

task :senderoxc => SENDEROXC_SRC do
  sh "rebuild senderoxc/Main.d -oqrebuild_objs -I../sendero_base -I../decorated_d -I../qcf -I../ddbi -version=dbi_mysql -ofbin/senderoxc -debug -debug=SenderoXCUnittest -L/DETAILEDMAP -g -version=Tango_0_99_7"
end

task :senderoxc_posix => SENDEROXC_SRC do
  sh "rebuild senderoxc/Main.d -oqrebuild_objs -I../sendero_base -I../decorated_d -I../qcf -I../ddbi -version=dbi_sqlite -version=dbi_mysql -ofbin/senderoxc -L-lsqlite3 -L-lmysqlclient -L-ldl -debug -debug=SenderoXCUnittest -g"
end

task :senderoimp => SENDEROXC_SRC do
  sh "rebuild senderoxc/util/ImportPrinter.d -oqrebuild_objs -I../sendero_base -I../decorated_d -I../qcf -ofbin/senderoimp -version=SenderoXCImportPrinter"
end

task :build => ["test_sendero.exe"]

task :build_server => ["test_server.exe" ]

task :build_server_client => ["test_server_client.exe"]

task :test_server => [:build_server] do
 sh "./test_server"
end

task :test_server_client => [:build_server_client] do
 sh "./test_server_client"
end

task :test_files => TEST_FILES

task :test => [:build, :test_files] do
  sh "test_sendero"
end

task :test_senderoxc => [:senderoxc] do
  sh "senderoxc"
end

task :build_scripts => SCRIPTS_SRC do
  sh "rebuild scripts/create_project.d -oqrebuild_objs -ofbin/sendero-create-project -Jscripts/templates"
end

task :default => [:test, :test_senderoxc]
