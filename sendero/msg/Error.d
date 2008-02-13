module sendero.msg.Error;

public import sendero.msg.Msg;

alias MsgMap ErrorMap;

class Error : Msg
{
	this()
	{
		register("Error");
	}
}

abstract class FieldError : Error
{
	
}

template SimpleError(char[] clsName)
{
	const char[] SimpleError = "static class " ~ clsName ~ " : Error"
	"{"
		"static " ~ clsName ~ " opCall()"
		"{"
		"	if(inst is null) inst = new " ~ clsName ~ ";"
		"   return inst;"
		"}"
		"static private " ~ clsName ~ " inst;"
		"private this()"
		"{"
			"register(\"" ~ clsName ~ "\");"
		"}"
	"}";
}