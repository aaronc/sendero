module senderoxc.Compiler;

import tango.io.File, tango.io.Path, tango.io.FilePath;
version(Tango_0_99_7) import tango.io.FileConduit;
else import tango.io.device.FileConduit;
import tango.io.Stdout;
import tango.util.log.Config;
import Util = tango.text.Util;
import sendero_base.util.ArrayWriter;

import decorated_d.compiler.Main;

import senderoxc.Config;
import senderoxc.Reset;

import senderoxc.builder.Build;
import senderoxc.builder.Linker;
import senderoxc.builder.Registry;

version(SenderoXCLive) {
	import ddl.DefaultRegistry;
	import ddl.Linker;
	import ddl.DynamicLibrary;
}

char[] regularizeDirname(char[] dirname)
{
	if(dirname.length && (dirname[$-1] != '/' || dirname[$-1] != '\\'))
		return dirname ~ "/";
	else return dirname;
}

interface IBuildService
{
	IBuildAgent getBuildAgent(char[] modname, char[] srcpath);
}

interface IBuildAgent
{
	bool compile(bool rebuildAll);
	bool link(bool rebuildAll);
}

interface IFileModService
{
	IFileModAgent getFileModAgent(char[] modname, char[] srcpath);
}

interface IFileModAgent
{
	bool checkAndClearModFlag();
	bool hasMods();
}

class SenderXCConfigProvider
{
	SenderoXCompiler[char[]] registeredModules;
	void reset()
	{
		registeredModules = null;
	}
}

class SenderoXCompiler
{
	this(char[] modname, DecoratedDCompiler compiler, char[] dirname = null)
	{
		this.modname = modname;
		auto fqname = Util.substitute(modname, ".", "-");
		version(Windows) this.objname = fqname ~ ".obj";
		else this.objname = fqname ~ ".o"; 
		this.compiler = compiler;
		this.dirname = dirname;
		
	}
	
	private void processImports(char[][] imports)
	{
		foreach(i; imports) registerImport(i);
	}
	 
	static SenderoXCompiler create(char[] modname)
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

		void onFindImportCallback(char[] modname)
		{
			imports ~= modname;
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
			//compiler.onImportStatement.attach((char[] modname){ imports ~= modname; });
			compiler.onImportStatement.attach(&onFindImportCallback);
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
				auto sxcompiler = new SenderoXCompiler(modname, compiler, dirname);
				Stdout.formatln("Registering compiler {}", modname);
				registeredModules[modname] = sxcompiler;
				sxcompiler.processImports(imports);
				return sxcompiler;
			}
			else {
				auto dcompiler = new DModuleCompiler(filename, modname, compiler);
				Stdout.formatln("Registering compiler {}", modname);
				registeredModules[modname] = dcompiler;
				dcompiler.processImports(imports);
				return dcompiler;
			}
		}
		else return null;
	}
	
	const char[] modname, dirname;
	const char[] objname;
	private char[] outname;
	private DecoratedDCompiler compiler;
	private bool processed_ = false;
	private bool written_ = false;
	private bool compiled_ = false;
	private bool linked_ = false;
	private bool modified_ = false;
	
	static SenderoXCompiler[char[]] registeredModules;
	
	final void registerImport(char[] modname)
	{
		auto cmp = SenderoXCompiler.create(modname);
		if(cmp !is null) {
			imports ~= cmp;
			//compiler.getModule.registerImport(cmp.compiler.getModule);
		}
	}
	
	final void process()
	{
		if(processed_) return;
		
		processed_ = true;
		
		Stdout.formatln("Processing module {}", modname);
		
		foreach(child; imports)
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
		
		foreach(child; imports)
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
		outname = outdir ~ fname ~ ".d";
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
		
		Stdout.formatln("Writing {}", outname);
		
		if(res.get != existingRes) {
			if(fpath.exists) copy(outname, outname ~ ".bak");
			Stdout.formatln("Commiting file {}", fpath.toString);
			auto resFile = new FileConduit(outname, FileConduit.WriteCreate);
			assert(resFile);
			resFile.write(res.get);
			resFile.flush.close;
			modified_ = true;
		}
		else Stdout.formatln("File {} is up-to-date", outname);
	}
	
	enum CompileStatus { Success, Ignore, Error };
	
	bool modified()
	{
		if(modified_) return true;
		foreach(i; imports)
			if(i.modified) return true;
		return false;
	}
	
	final CompileStatus compile(bool rebuildAll)
	{
		if(compiled_) return CompileStatus.Ignore;
		
		compiled_ = true;
		
		Stdout.formatln("Compiling module {}", modname);
		
		bool doCompile = false;
		
		foreach(child; imports) {
			auto res = child.compile(rebuildAll);
			if(res == CompileStatus.Error) return CompileStatus.Error;
			else if(res == CompileStatus.Success) doCompile = true;
		}
		
		if(!modified && !doCompile && !rebuildAll) return CompileStatus.Ignore;
		else {
			return compileThis ? CompileStatus.Success : CompileStatus.Error;
		}
	}
	
	bool compileThis()
	in { assert(outname.length); }
	body
	{
		modified_ = false;
		auto res = BuildCommand.execute(modname, outname, objname);
		SenderoXCRegistry.register(modname, Time(0), res);
		return res;
	}
	
	void link(SenderoXCLinker linker)
	{
		if(linked_) return;
		linked_ = true;
		
		linker.link(objname);
		
		foreach(child; imports) {
			child.link(linker);
		}
	}
	
	SenderoXCompiler[] imports;
	
	static void reset()
	{
		registeredModules = null;
		SenderoXCReset.onReset();
	}
}

class DModuleCompiler : SenderoXCompiler
{
	this(char[] filename, char[] modname, DecoratedDCompiler compiler)
	{
		this.filename_ = filename;
		this.filepath_ = new FilePath(filename_);
		//this.lastModified_ = filepath_.modified;
		super(modname, compiler);
	}
	
	void processThis() {
		
	}
	
	void writeThis(char[] outdir = null) {
		
	}
	
	bool modified()
	{
		if(SenderoXCRegistry.lastModified(modname) != filepath_.modified) return true;
		foreach(i; imports)
			if(i.modified) return true;
		return false;
	}
	
	bool compileThis()
	in { assert(filename_.length); }
	body
	{
		//lastModified_ = filepath_.modified;
		//return BuildCommand.execute(modname, filename_, objname);
		auto res = BuildCommand.execute(modname, filename_, objname);
		SenderoXCRegistry.register(modname, filepath_.modified, res);
		return res;
	}
	
	private char[] filename_;
	private FilePath filepath_;
	private Time lastModified_;
}
