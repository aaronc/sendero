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