module senderoxc.Compiler;

import tango.io.File, tango.io.FileConduit, tango.io.Path;
import tango.io.Stdout;
import tango.util.log.Config;
import Util = tango.text.Util;
import sendero_base.util.ArrayWriter;

import decorated_d.compiler.Main;

class SenderoXCCompiler
{
	this(char[] modname, DecoratedDCompiler compiler, char[][] imports)
	{
		this.modname = modname;
		this.compiler = compiler;
		foreach(i; imports) registerImport(i);
	}
	
	static SenderoXCCompiler create(char[] modname)
	{
		auto pCompiler = modname in registeredModules;
		if(pCompiler !is null)
			return *pCompiler;
		
		char[][] imports;
		
		char[] readFile(char[] fname)
		{
			Stdout.formatln("Opening file {}", fname);
			auto f = new File(fname);
			assert(f, fname);
			return cast(char[])f.read;
		}
		
		DecoratedDCompiler createDDCompiler(char[] src, char[] fname)
		{
			auto compiler = new DecoratedDCompiler(src, fname);
			assert(compiler);
			compiler.onImportStatement.attach((char[] modname){ imports ~= modname; });
			assert(compiler.parse);
			compiler.build;
			
			return compiler;
		}
		
		Stdout.formatln("Reading module {}", modname);
		
		auto fname = Util.substitute(modname, ".", "/");
		
		if(exists(fname ~ ".sdx")) {
			//auto outname = fname ~ ".d";
			fname ~= ".sdx";
			auto src = readFile(fname);
			
			/+char[] existingRes;
			
			if(exists(outname)) {
				auto existingResFile = new File(outname);
				existingRes = cast(char[])existingResFile.read;
			}+/
			
			auto compiler = createDDCompiler(src, fname);
			
			auto sxcompiler = new SenderoXCCompiler(modname, compiler, imports);
			registeredModules[modname] = sxcompiler;
			return sxcompiler;
			
			/+auto res = new ArrayWriter!(char);			
			assert(compiler.parse);
			compiler.build.process.finish(&res.append, outname);
			
			if(res.get != existingRes) {
				auto resFile = new FileConduit(outname, FileConduit.WriteCreate);
				resFile.write(res.get);
				resFile.flush.close;
			}+/
		}
		else if(exists(fname ~ ".d")) {
			fname ~= ".d";
			auto src = readFile(fname);
			auto compiler = createDDCompiler(src, fname);
			
			auto dcompiler = new DModuleCompiler(modname, compiler, imports);
			registeredModules[modname] = dcompiler;
			return dcompiler;
		}
		else return null;
	}
	
	const char[] modname;
	private DecoratedDCompiler compiler;
	private bool processed_ = false;
	private bool written_ = false;
	
	static SenderoXCCompiler[char[]] registeredModules;
	
	final void registerImport(char[] modname)
	{
		auto compiler = SenderoXCCompiler.create(modname);
		if(compiler !is null) imports[modname] = compiler;
	}
	
	final void process()
	{
		if(processed_) return;
		
		processed_ = true;
		
		Stdout.formatln("Processing module {}", modname);
		
		foreach(name, child; imports)
			child.process;
		
		processThis;
	}
	
	void processThis()
	{
		compiler.process;
	}
	
	final void write()
	{
		if(written_) return;
		
		written_ = true;
		
		Stdout.formatln("Writing module {}", modname);
		
		writeThis;
	}
	
	void writeThis()
	{
		auto outname = modname ~ ".d";
		
		char[] existingRes;
		
		if(exists(outname)) {
			auto existingResFile = new File(outname);
			existingRes = cast(char[])existingResFile.read;
		}
		
		auto res = new ArrayWriter!(char);			
		compiler.finish(&res.append, outname);
		
		if(res.get != existingRes) {
			auto resFile = new FileConduit(outname, FileConduit.WriteCreate);
			resFile.write(res.get);
			resFile.flush.close;
		}
	}
	
	SenderoXCCompiler[char[]] imports;
	
	/+static char[][char[]] compiledModules;
	
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
	}+/
}

class DModuleCompiler : SenderoXCCompiler
{
	this(char[] modname, DecoratedDCompiler compiler, char[][] imports)
	{
		super(modname, compiler, imports);
	}
	
	void processThis() {
		
	}
	void writeThis() {
		
	}
}