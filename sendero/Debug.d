module sendero.Debug;

public import tango.util.log.Log, tango.util.log.Config;

template FailTrace(char[] MethodName, char[] Log = "log")
{
	const char[] FailTrace = `const char[] MName = "` ~ MethodName ~ `";` ~ 
		Log ~`.trace(MName ~ " ENTER");`
		`scope(success) ` ~ Log ~`.trace(MName ~ " SUCCESS");`
		`scope(failure) ` ~ Log ~`.trace(MName ~ " FAILURE");`
	;
}