module sendero.core.Config;

import tango.io.File, tango.io.FilePath;
import sendero_base.confscript.Parser, sendero_base.Serialization;

import sendero.Exception;

class SenderoConfig
{
	private this() {}
	
	static void load(char[] configName, char[] filename = "sendero.conf")
	{
		auto fp = new FilePath(filename);
		
		if(!fp.exists) return;
		
		auto f = new File(fp.toString);
		if(!f) return;
		
		auto cfgSrc = cast(char[])f.read;
		
		auto cfgObj = parseConf(cfgSrc);
		
		auto cfg = cfgObj[configName];
		
		if(cfg.type == VarT.Object) {
			inst = new SenderoConfig;
			deserialize(inst, cfg.obj_);
		}
		else throw new SenderoException("Unable to find configuration " ~ configName ~ " in " ~ filename);
	}
	
	private static SenderoConfig inst;
	
	static SenderoConfig opCall()
	{
		return inst;
	}
	
	char[] dbUrl;
	
	void serialize(Ar)(Ar ar)
	{
		ar (dbUrl, "db");
	}
}
