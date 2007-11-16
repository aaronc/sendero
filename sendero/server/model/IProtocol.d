
module sendero.server2.model.IProtocol;
import tango.io.model.IConduit;
import tango.io.selector.model.ISelector;
import tango.io.model.IBuffer;

/**
	* IProtocol
	* Interface for pluggable protocol handlers in a server
	* Will offer several functions to be called back to parse
	* validate, and respond to network traffic.
	*/

interface IProtocol
{
  static int validateRequest(IBuffer);
  int handleRequest(IBuffer, ISelectable);
}

enum Validator : int
{
  COMPLETE = 0,
  INVALID = -1,
  INCOMPLETE = 1
}
