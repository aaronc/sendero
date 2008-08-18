module sendero.core.Config;

import sendero.util.AbstractConfig;

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
