module senderoxc.Compiler;

import tango.io.File, tango.io.FileConduit, tango.io.Path;
import tango.io.Stdout;
import tango.util.log.Config;
import Util = tango.text.Util;
import sendero_base.util.ArrayWriter;

import decorated_d.compiler.Main;

class SenderoXCCompiler
{
	static char[][char[]] compiledModules;
	
	char[] justCompile(char[] modname)
	{
		if(modname in compiledModules) return null;
		compiledModules[modname] = modname;
		
		auto fname = Util.substitute(modname, ".", "/");
		fname ~= ".sdx";
		
		if(exists(fname)) {
			
			Stdout.formatln("Opening file {}", fname);
			auto f = new File(fname);
			auto src = cast(char[])f.read;
			
			auto res = new ArrayWriter!(char);			
			auto compiler = new DecoratedDCompiler(src, fname);
			compiler.onImportStatement.attach(&this.compile);
			assert(compiler.parse);
			compiler.build.process.finish(&res.append, "");
			
			return res.get;
		}
		else return null;
	}
	
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
			auto compiler = new DecoratedDCompiler(src, fname);
			compiler.onImportStatement.attach(&this.compile);
			assert(compiler.parse);
			compiler.build.process.finish(&res.append, outname);
			
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
			
			auto compiler = new DecoratedDCompiler(src, fname);
			compiler.onImportStatement.attach(&this.compile);
			assert(compiler.parse);
			compiler.build;
		}
	}
}