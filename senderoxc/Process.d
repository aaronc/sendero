module senderoxc.Process;

import tango.io.File, tango.io.Path;
version(Tango_0_99_7) import tango.io.FileConduit;
else import tango.io.device.FileConduit;
import tango.io.Stdout;
import tango.util.log.Config;
import Util = tango.text.Util;

import sendero_base.confscript.Parser;
import sendero_base.Serialization;

import senderoxc.SenderoExt;
import senderoxc.data.Schema;
import senderoxc.Compiler;
import senderoxc.Config;
import senderoxc.builder.Linker;

import sendero.core.Config;

import dbi.DBI;

import tango.util.log.Log;
Logger log;
static this()
{
	log = Log.lookup("senderoxc.Process");
}

version(dbi_mysql) {
	import senderoxc.data.MysqlMapper;
}

void init(char[] configName)
{
	log.trace("Initializing config {}", configName);
	SenderoConfig.load(configName);
	SenderoXCConfig.load(configName);
	log.trace("Initialized config {}", configName);
}

void run(char[] modname, char[] outdir = null)
{
	Stdout.formatln("Running SenderoXC on module {}", modname);
	
	try
	{
		auto compiler = SenderoXCompiler.create(modname);
		assert(compiler);
		compiler.process;
		compiler.write(outdir);
		version(SenderoXCBuild) {
			if(compiler.compile(false) == SenderoXCompiler.CompileStatus.Success) {
				version(SenderoXCLive) {
					compiler.link;
				}
				auto linker = new SenderoXCLinker(SenderoXCConfig().target);
				compiler.link(linker);
				linker.commit;
			}
		}
	}
	catch(Exception ex)
	{
		Stdout.formatln("Caught exception: {}", ex.toString);
		if(ex.info) {
			Stdout.formatln("Stack trace");
			Stdout(ex.info.toString).newline;
		}
		throw ex;
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
		if(ex.info) {
			Stdout.formatln("Stack trace");
			Stdout(ex.info.toString).newline;
		}
		throw ex;
	}
}
