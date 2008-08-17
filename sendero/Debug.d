module sendero.Debug;

public import tango.util.log.Log;

template FailTrace(char[] MethodName, char[] Log = "log")
{
	const char[] FailTrace = `const char[] MName = "` ~ MethodName ~ `";` ~ 
		Log ~`.trace(MName ~ " ENTER");`
		`scope(success) ` ~ Log ~`.trace(MName ~ " SUCCESS");`
		`scope(failure) ` ~ Log ~`.trace(MName ~ " FAILURE");`
	;
}

debug(SenderoRuntime) {

import tango.util.log.AppendFile, tango.util.log.LayoutDate;
import tango.io.Path;
import tango.io.File;

class SenderoAppender : AppendFile
{
	this(char[] logName, Appender.Layout how = null)
	{
		if(!exists("../logs")) createFolder("../logs");
		super("../logs/" ~ logName ~ ".log", how);
	}
}

static this()
{
	Log.lookup("debug").add(new SenderoAppender("debug", new LayoutDate));
}

void initOptlinkMap(char[] filename) {
	OptlinkMap.init(filename);
}

import cn.kuehne.flectioned;

char[] dumpAddresses()
{
	char[] res;
	
	/+res ~= "<br /><br />";
	OptlinkMap.init;
	foreach(e; OptlinkMap.entries)
	{
		res ~= e.toString ~ "<br />";
	}+/
	
	/+res ~= "<br /><br />";
	foreach(addr, sym; addresses)
	{
		res ~= sym.toString ~ "<br />";
	}
	
	res ~= "<br /><br />";
	
	foreach(name, f; functions)
	{
		res ~= name ~ "<br />";
	}+/
	
	return res;
}

}
else import tango.util.log.Config;