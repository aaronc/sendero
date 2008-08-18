module senderoxc.Compiler;

import tango.io.File, tango.io.FileConduit, tango.io.Path, tango.io.FilePath;
import tango.io.Stdout;
import tango.util.log.Config;
import Util = tango.text.Util;
import sendero_base.util.ArrayWriter;

import decorated_d.compiler.Main;

import senderoxc.Config;
import senderoxc.Reset;

char[] regularizeDirname(char[] dirname)
{
	if(dirname.length && (dirname[$-1] != '/' || dirname[$-1] != '\\'))
		return dirname ~ "/";
	else return dirname;
}

class SenderoXCCompiler
{
	this(char[] modname, DecoratedDCompiler compiler, char[][] imports, char[] dirname = null)
	{
		this.modname = modname;
		this.compiler = compiler;
		this.dirname = dirname;
		foreach(i; imports) registerImport(i);
	}
	
	static SenderoXCCompiler create(char[] modname)
	{
		auto pCompiler = modname in registeredModules;
		if(pCompiler !is null)
			return *pCompiler;
		
		char[][] imports;
		
		bool openModule(char[] modname, out char[] filename, out bool isSDX, out char[] dir)
		{
			filename = null;
			isSDX = false;
			dir = null;
			
			auto fname = Util.substitute(modname, ".", "/");
			
			auto sdxname = fname ~ ".sdx";
			
			if(exists(sdxname)) {
				filename = sdxname;
				isSDX = true;
				return true;
			}
			
			foreach(includeDir; SenderoXCConfig().includeDirs)
			{
				auto dirname = regularizeDirname(includeDir);
				if(exists(dirname ~ sdxname))
				{
					filename = dirname ~ sdxname;
					isSDX = true;
					dir = dirname;
					return true;
				}
			}
			
			auto dname = fname ~ ".d";
			
			if(exists(dname)) {
				filename = dname;
				isSDX = false;
				return true;
			}
			
			foreach(includeDir; SenderoXCConfig().includeDirs)
			{
				auto dirname = regularizeDirname(includeDir);
				if(exists(dirname ~ dname))
				{
					filename = dirname ~ dname;
					isSDX = false;
					dir = dirname;
					return true;
				}
			}
			
			return false;
		}

		DecoratedDCompiler createDDCompiler(char[] fname)
		{
			//Read File
			Stdout.formatln("Opening file {}", fname);
			auto f = new File(fname);
			assert(f, fname);
			auto src = cast(char[])f.read;
			
			// Create Compiler
			auto compiler = new DecoratedDCompiler(src, fname);
			assert(compiler);
			compiler.onImportStatement.attach((char[] modname){ imports ~= modname; });
			assert(compiler.parse);
			compiler.build;
			
			return compiler;
		}
		
		Stdout.formatln("Looking for module {}", modname);
		
		char[] filename, dirname;
		bool isSDX;
		
		if(openModule(modname, filename, isSDX, dirname))
		{
			auto compiler = createDDCompiler(filename);
			if(isSDX) {
				auto sxcompiler = new SenderoXCCompiler(modname, compiler, imports, dirname);
				registeredModules[modname] = sxcompiler;
				return sxcompiler;
			}
			else {
				auto dcompiler = new DModuleCompiler(modname, compiler, imports);
				registeredModules[modname] = dcompiler;
				return dcompiler;
			}
		}
		else return null;
	}
	
	const char[] modname, dirname;
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
	
	protected void processThis()
	{
		compiler.process;
	}
	
	final void write(char[] outdir = null)
	{
		if(written_) return;
		
		written_ = true;
		
		Stdout.formatln("Writing module {}", modname);
		
		foreach(name, child; imports)
			child.write(outdir);
		
		writeThis(outdir);
	}
	
	protected void writeThis(char[] outdir = null)
	{
		if(outdir.length) {
			outdir = regularizeDirname(outdir);
			Stdout.formatln("Writing to directory {}", outdir);
		}
		else {
			outdir = dirname;
			Stdout.formatln("Writing to directory {}", outdir);
		}
		
		auto fname = Util.substitute(modname, ".", "/");
		char[] outname = outdir ~ fname ~ ".d";
		auto fpath = new FilePath(outname);
		if(!exists(fpath.parent)) {
			createFolder(fpath.parent);
		}
		
		char[] existingRes;
		
		if(fpath.exists) {
			auto existingResFile = new File(fpath.toString);
			assert(existingResFile);
			existingRes = cast(char[])existingResFile.read;
		}
		
		auto res = new ArrayWriter!(char);			
		compiler.finish(&res.append, outname);
		
		if(res.get != existingRes) {
			if(fpath.exists) copy(outname, outname ~ ".bak");
			Stdout.formatln("Commiting file {}", fpath.toString);
			auto resFile = new FileConduit(outname, FileConduit.WriteCreate);
			assert(resFile);
			resFile.write(res.get);
			resFile.flush.close;
		}
		else Stdout.formatln("File {} is up-to-date", outname);
	}
	
	void compile()
	{
		
	}
	
	SenderoXCCompiler[char[]] imports;
	
	static void reset()
	{
		registeredModules = null;
		SenderoXCReset.onReset();
	}
}

class DModuleCompiler : SenderoXCCompiler
{
	this(char[] modname, DecoratedDCompiler compiler, char[][] imports)
	{
		super(modname, compiler, imports);
	}
	
	void processThis() {
		
	}
	
	void writeThis(char[] outdir = null) {
		
	}
	
	void compile()
	{
		
	}
}