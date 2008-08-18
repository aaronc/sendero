module senderoxc.Main;

import tango.io.File, tango.io.FileConduit, tango.io.Path;
import tango.io.Stdout;
import tango.util.log.Config;
import Util = tango.text.Util;

import sendero_base.confscript.Parser;
import sendero_base.Serialization;

import senderoxc.SenderoExt;
import senderoxc.data.Schema;
import senderoxc.Compiler;
import senderoxc.Config;

import sendero.core.Config;

import dbi.all;

version(dbi_mysql) {
	import senderoxc.data.MysqlMapper;
}

debug(SenderoXCUnittest) {
	import qcf.Regression;
	import qcf.TestRunner;
	import qcf.StackTrace;
	import tango.util.log.Config;
	static this() { initOptlinkMap("senderoxc.map"); }
}

int main(char[][] args)
{
	void run(char[] modname, char[] outdir = null)
	{
		Stdout.formatln("Running SenderoXC on module {}", modname);
		
		try
		{
			auto compiler = SenderoXCCompiler.create(modname);
			assert(compiler);
			compiler.process;
			compiler.write(outdir);
		}
		catch(Exception ex)
		{
			Stdout.formatln("Caught exception: {}", ex.toString);
			if(ex.info) {
				Stdout.formatln("Stack trace");
				Stdout(ex.info.toString).newline;
			}
		}
		
		try
		{
			Stdout.formatln("Committing db schema to {}", SenderoConfig().dbUrl);
			auto db = getDatabaseForURL(SenderoConfig().dbUrl);
			Schema.commit(db);
			db.close;
		}
		catch(Exception ex)
		{
			Stdout.formatln("Caught exception: {}, while commiting db schema", ex.toString);
		}
	}
	
	if(args.length > 1) {
		SenderoConfig.load(args[1]);
		SenderoXCConfig.load(args[1]);
		
		run(SenderoXCConfig().modname);
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
			SenderoXCCompiler.reset;
			
			Stdout.formatln("Runing Mysql tests");
			SenderoConfig.load("test_mysql");
			run("test1", "test/senderoxc/mysql");
			regression = new Regression("senderoxc/mysql");
			regression.regressFile("test1.d");
			regression.regressFile("test2.d");
			regression.regressFile("IUser.d");
		}
	}
	
	return 0;
}