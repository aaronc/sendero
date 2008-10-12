module senderoxc.builder.Build;

import senderoxc.builder.BuildFlags;

import tango.io.Stdout;
import tango.text.Util;
import tango.sys.Process;

class BuildCommand
{
	static char[] execute(char[] modname, char[] filename)
	{
		char[] cmd;
		auto objname = write(modname, filename, (char[] val) { cmd ~= val; });
		Stdout.formatln("Running build command: {}", cmd);
		auto p = new Process(cmd, null);
		p.execute;
		Stdout.copy (p.stdout).flush;
	    auto res = p.wait;
	    if(res.status != 0) {
	    	Stdout.formatln("dmd exited with return code {}", res.status);
	    	return null;
	    }
	    return objname;
	}
	
	static char[] write(char[] modname, char[] filename, void delegate(char[]) wr)
	{
		wr("dmd -c ");
		BuildFlags.write(wr);
		wr(" -of");
		auto fqname = replace(modname, '.', '-');
		wr(fqname);
		wr(".obj ");
		wr(filename);
		
		return "senderoxc_objs/" ~ fqname ~ ".obj";
	}
}