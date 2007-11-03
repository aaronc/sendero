
module sendero.server2.model.IProtocol;
import tango.io.model.IConduit;
import tango.io.selector.model.ISelector;
import sendero.util.FastBuffer;

/**
	* IProtocol
	* Interface for pluggable protocol handlers in a server
	* Will offer several functions to be called back to parse
	* validate, and respond to network traffic.
	*/

interface IProtocol
{
	static int validateRequest(FastBuffer);
	int handleRequest(FastBuffer, ISelectable);
}
