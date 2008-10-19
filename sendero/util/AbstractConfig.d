module sendero.util.AbstractConfig;

public import tango.io.File, tango.io.FilePath;
public import sendero_base.confscript.Parser, sendero_base.Serialization;

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
		
		auto defCfg = cfgObj[""];
		auto cfg = cfgObj[configName];
		
		auto newInst = new T;
		
		if(defCfg.type == VarT.Object) {
			deserialize(newInst, defCfg.obj_);
		}
		
		if(cfg.type == VarT.Object) {
			deserialize(newInst, cfg.obj_);
		}
		//else throw new SenderoException("Unable to find configuration " ~ configName ~ " in " ~ filename);
		
		inst = newInst;
	}

}