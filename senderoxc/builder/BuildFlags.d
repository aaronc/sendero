module senderoxc.builder.BuildFlags;

import senderoxc.Config;

class BuildFlags
{	
	static void write(void delegate(char[]) wr)
	{
		foreach(dir; SenderoXCConfig().includeDirs)
		{
			wr("-I");
			wr(dir);
			wr(" ");
		}
		
		foreach(dir; SenderoXCGlobalConfig().includeDirs)
		{
			wr("-I");
			wr(dir);
			wr(" ");
		}
		
		wr("-odsenderoxc_objs");
	}
}