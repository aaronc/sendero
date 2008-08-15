module senderoxc.Main;

import tango.io.File, tango.io.FileConduit, tango.io.Path;
import tango.io.Stdout;
import tango.util.log.Config;
import Util = tango.text.Util;

import sendero_base.confscript.Parser;
import sendero_base.Serialization;

import decorated_d.compiler.Main;

import senderoxc.SenderoExt;

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
	void compile(char[] modname)
	{
		auto fname = Util.substitute(modname, ".", "/");
		
		if(exists(fname ~ ".sdx")) {
			auto outname = fname ~ ".d";
			fname ~= ".sdx";
			Stdout.formatln("Opening file {}", fname);
			auto f = new File(fname);
			auto src = cast(char[])f.read;
			auto res = new FileConduit(outname, FileConduit.WriteCreate);
			
			auto compiler = new DecoratedDCompiler;
			compiler.onImportStatement.attach(&this.compile);
			assert(compiler.compile(src,cast(void delegate(char[]))&res.write, fname, outname));
			res.flush.close;
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
	
	
	
	if(args.length > 1) {
		auto compiler = new SenderoXCCompiler;
		compiler.compile(args[1]);
		
		/+auto fname = Util.substitute(args[1], ".", "/");
		auto outname = fname ~ ".d";
		fname ~= ".sdx";
		
		Stdout.formatln("Opening file {}", fname);
		auto f = new File(fname);
		auto src = cast(char[])f.read;
		auto res = new FileConduit(outname, FileConduit.WriteCreate);
		
		auto compiler = new DecoratedDCompiler;
		assert(compiler.compile(src,cast(void delegate(char[]))&res.write, fname, outname));
		res.flush.close;+/
	}
	
	return 0;
}