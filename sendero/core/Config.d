module sendero.core.Config;

import tango.io.File, tango.io.FilePath;
import sendero_base.confscript.Parser, sendero_base.Serialization;

public import sendero.Exception;

template Config(T)
{
	static this()
	{
		inst = new T;
	}
	
	private this() {}
	
	static T opCall()
	{
		return inst;
	}	

	private static T inst;
		
	private static void loadConfig(char[] configName, char[] filename)
	{
		auto fp = new FilePath(filename);
		
		if(!fp.exists) return;
		
		auto f = new File(fp.toString);
		if(!f) return;
		
		auto cfgSrc = cast(char[])f.read;
		
		auto cfgObj = parseConf(cfgSrc);
		
		auto cfg = cfgObj[configName];
		
		if(cfg.type == VarT.Object) {
			inst = new T;
			deserialize(inst, cfg.obj_);
		}
		else throw new SenderoException("Unable to find configuration " ~ configName ~ " in " ~ filename);
	}

}

class SenderoConfig
{
	mixin Config!(SenderoConfig);
	
	static void load(char[] configName, char[] filename = "sendero.conf")
	{
		loadConfig(configName, filename);
	}
	
	char[] dbUrl = "sqlite://sendero_debug.sqlite";
	
	void serialize(Ar)(Ar ar)
	{
		ar (dbUrl, "db");
	}
}
