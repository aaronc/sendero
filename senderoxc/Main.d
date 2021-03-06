module senderoxc.Main;

import senderoxc.Process;

import senderoxc.Compiler;
import senderoxc.Config;
import sendero.core.Config;

import tango.io.Stdout;


debug(SenderoXCUnittest) {
	import qcf.Regression;
	import qcf.TestRunner;
	import qcf.StackTrace;
	import tango.util.log.Config;
	version(Windows) static this() { initOptlinkMap("senderoxc.map"); }
}

int main(char[][] args)
{
	if(args.length > 1) {
		init(args[1]);
		if(!run(SenderoXCConfig().modname))
			return -1;
	}
	else debug(SenderoXCUnittest) {
		Stdout.formatln("Runing Sqlite tests");
		
		SenderoConfig.load("test");
		SenderoXCConfig().includeDirs ~= "test/senderoxc";
		
		run("test1");
		auto regression = new Regression("senderoxc");
		regression.regressFile("test1.d");
		regression.regressFile("test2.d");
		regression.regressFile("IUser.d");
		
		
		version(dbi_mysql) {
			SenderoXCompiler.reset;
			
			Stdout.formatln("Runing Mysql tests");
			SenderoConfig.load("test_mysql");
			if(!run("test1", "test/senderoxc/mysql"))
				return -1;
			regression = new Regression("senderoxc/mysql");
			regression.regressFile("test1.d");
			regression.regressFile("test2.d");
			regression.regressFile("IUser.d");
		}
	}
	
	return 0;
}