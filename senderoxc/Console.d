module senderoxc.Console;

import  tango.io.Print, tango.io.Console;
import  tango.text.convert.Layout;

Print!(char) sxcout;

static this()
{
	auto layout = new Layout!(char);

	sxcout = new Print!(char) (layout, Cout.stream);
    
	sxcout.flush = !Cout.redirected;
}

