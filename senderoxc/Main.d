module senderoxc.Main;

import tango.io.File, tango.io.FileConduit, tango.io.Path;
import tango.io.Stdout;
import tango.util.log.Config;
import Util = tango.text.Util;

import sendero_base.confscript.Parser;
import sendero_base.Serialization;
import sendero_base.util.ArrayWriter;

import decorated_d.compiler.Main;

import senderoxc.SenderoExt;
import senderoxc.data.Schema;

import dbi.all;

debug(SenderoXCUnittest) {
	import qcf.Regression;
	import qcf.TestRunner;
}

class Conf
{
	char[][] includeDirs;
	
	void serialize(Ar)(Ar ar)
	{
		ar (includeDirs, "includeDirs");
	}
}

class SenderoXCCompiler
{
	static char[][char[]] compiledModules;
	
	void compile(char[] modname)
	{
		// Check for cyclic dependencies
		if(modname in compiledModules) return;
		compiledModules[modname] = modname;
		
		auto fname = Util.substitute(modname, ".", "/");
		
		if(exists(fname ~ ".sdx")) {
			auto outname = fname ~ ".d";
			fname ~= ".sdx";
			Stdout.formatln("Opening file {}", fname);
			auto f = new File(fname);
			auto src = cast(char[])f.read;
			
			char[] existingRes;
			
			if(exists(outname)) {
				auto existingResFile = new File(outname);
				existingRes = cast(char[])existingResFile.read;
			}
			
			auto res = new ArrayWriter!(char);			
			auto compiler = new DecoratedDCompiler;
			compiler.onImportStatement.attach(&this.compile);
			assert(compiler.compile(src,&res.append, fname, outname));
			
			if(res.get != existingRes) {
				auto resFile = new FileConduit(outname, FileConduit.WriteCreate);
				resFile.write(res.get);
				resFile.flush.close;
			}
		}
		else if(exists(fname ~ ".d")) {
			fname ~= ".d";
			Stdout.formatln("Opening file {}", fname);
			auto f = new File(fname);
			auto src = cast(char[])f.read;
			
			auto compiler = new DecoratedDCompiler;
			compiler.onImportStatement.attach(&this.compile);
			assert(compiler.compile(src,(char[]){}, fname, null));
		}
	}
}

int main(char[][] args)
{
	/+auto confFile = new File("senderoxc.conf");
	if(!confFile) {
		Stdout.formatln("Unable to find senderoxc.conf");
		return -1;
	}
	
	auto confObj = parseConf(cast(char[])confFile.read);
	auto conf = new Conf;
	auto v = confObj[""];
	if(v.type == VarT.Object)
		Deserializer.deserialize(conf, v.obj_);+/
	
	//DecoratedDCompiler.addModuleContext();
	
	void run(char[] modname)
	{
		auto compiler = new SenderoXCCompiler;	
		compiler.compile(modname);
			
		debug {
			try
			{
				auto db = getDatabaseForURL("sqlite://senderoxc_debug.sqlite");
				Schema.commit(db);
				db.close;
			}
			catch(Exception ex)
			{
				Stdout.formatln("Caught exception: {}, while commiting db schema", ex.toString);
			}
		}
	}
	
	if(args.length > 1) {
		run(args[1]);
	}
	else debug(SenderoXCUnittest) {
		run("test.senderoxc.test1");
		auto regression = new Regression("senderoxc");
		regression.regressFile("test1.d");
		regression.regressFile("test2.d");
	}
	
	return 0;
}