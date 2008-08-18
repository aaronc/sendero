module senderoxc.Reset;

import tango.core.Signal;

struct SenderoXCReset
{
	static Signal!() onReset;
}