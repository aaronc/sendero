module senderoxc.Config;

import sendero.util.AbstractConfig;

class SenderoXCConfig
{
	mixin Config!(SenderoXCConfig);
	
	char[][] includeDirs;
	char[] modname;
	char[] buildflags;
	
	static void load(char[] configName, char[] filename = "senderoxc.conf")
	{
		loadConfig(configName, filename);
	}
	
	void serialize(Ar)(Ar ar)
	{
		ar (modname, "name") (includeDirs, "includeDirs") (buildflags, "buildflags");
	}
}

class SenderoXCGlobalConfig
{
	mixin Config!(SenderoXCConfig);
	
	char[][] includeDirs;
	
	static void load(char[] filename = "senderoxc_globals.conf")
	{
		loadConfig("Environment", filename);
	}
	
	void serialize(Ar)(Ar ar)
	{
		(includeDirs, "includeDirs");
	}
}