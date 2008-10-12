module senderoxc.builder.Linker;

import senderoxc.Console;
import tango.sys.Process;

version(SenderoXCLive) {
	import senderoxc.builder.Live;

class SenderoXCLinker
{
	void link(char[] objname)
	{
		
	}
	
	void commit()
	{
		
	}
}

}
else {
	
class SenderoXCLinker
{
	this(char[] target)
	{
		if(!target.length) this.target_ = "__senderoxc_out__";
		else this.target_ = target;
		cmd_ = "dmd ";
	}
	
	void link(char[] objname)
	{
		if(!(objname in objMap_)) {
			cmd_ ~= "senderoxc_objs\\" ~ objname ~ " ";
			objMap_[objname] = objname;
		}
	}
	
	char[][char[]] objMap_;
	
	void commit()
	{
		cmd_ ~= "-of" ~ target_;
		cmd_ ~= " -defaultlib=tango-base-dmd.lib";
		cmd_ ~= " -debuglib=tango-base-dmd.lib";
		cmd_ ~= " -L+tango-user-dmd.lib";
		sxcout.formatln("Running link command: {}", cmd_);
		auto p = new Process(cmd_, null);
		p.execute;
		sxcout.copy (p.stdout).flush;
	    auto res = p.wait;
	    if(res.status != 0) {
	    	sxcout.formatln("dmd exited with return code {}", res.status);
	    }
	}
	
	private char[] cmd_, target_;
}

}