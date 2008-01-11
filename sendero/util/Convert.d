module sendero.util.Convert;

import tango.core.Traits;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

void fromString(Char, T)(Char[] str, inout T t)
{
	if(str is null) {
		t = T.init;
		return;
	}
	
	static if(is(T == char[]))
	{
		t = str;
	}
	else static if(isIntegerType!(T))
	{
		t = Integer.parse(str);
	}
	else static if(isRealType!(T))
	{
		t = Float.parse(str);
	}
}