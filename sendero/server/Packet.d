module sendero.server.Packet;

public import tango.net.SocketConduit;

class Packet
{
	this(SocketConduit cond, char[] data)
	{
		this.cond = cond;
		this.data = data;
	}
	
	SocketConduit cond;
	char[] data;
}
