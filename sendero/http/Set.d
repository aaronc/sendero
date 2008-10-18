module sendero.http.Set;

import tango.core.Traits;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

void convert(T)(Var var, inout T t)
{
	static if(is(T == char[]))
	{
		
	}
	else static if(is(T == bool))
	{
		
	}
	else static if(isIntegerType!(T))
	{
		
	}
	else static if(isRealType!(T))
	{
		
	}
	else static if(is(T == Time))
	{
		
	}
	else static if(is(T == DateTime))
	{
		
	}
	else static if(is(T == Date))
	{
		
	}
	else static if(is(T == TimeOfDay))
	{
		
	}
	else static if(is(T == TimeSpan))
	{
		
	}
	else static if(is(T == void[]) || is(T == ubyte[]))
	{
		
	}
	else static if(is(T == class))
	{
		
	}
	else static assert(false, "Unsupported convert type " ~ T.stringof);
}