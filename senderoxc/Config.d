module senderoxc.Config;

import sendero.util.AbstractConfig;

class SenderoXCConfig
{
	mixin Config!(SenderoXCConfig);
	
	char[][] includeDirs;
	char[] modname;
	
	static void load(char[] configName, char[] filename = "senderoxc.conf")
	{
		loadConfig(configName, filename);
	}
	
	void serialize(Ar)(Ar ar)
	{
		ar (modname, "name") (includeDirs, "includeDirs");
	}
}