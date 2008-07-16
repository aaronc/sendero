module senderoxc.Main;

import tango.io.File;
import tango.io.Stdout;

import sendero_base.confscript.Parser;
import sendero_base.Serialization;

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
	auto confFile = new File("senderoxc.conf");
	if(!confFile) {
		Stdout.formatln("Unable to find senderoxc.conf");
		return -1;
	}
	
	auto confObj = parseConf(cast(char[])confFile.read);
	auto conf = new Conf;
	auto v = confObj[""];
	if(v.type == VarT.Obj)
		Deserializer.deserialize(conf, v.obj_);
}