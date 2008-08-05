module senderoxc.Main;

import tango.io.File;
import tango.io.Stdout;
import tango.util.log.Config;

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
		Stdout.formatln("Opening file {}", args[1]);
		auto f = new File(args[1]);
		auto src = cast(char[])f.read;
		
		auto compiler = new DecoratedDCompiler;
		assert(compiler.compile(src,(char[] val) {
			Stdout(val);
		}), args[1]);
	}
	
	return 0;
}