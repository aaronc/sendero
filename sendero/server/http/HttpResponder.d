module sendero.server.http.HttpResponder;

import tango.io.device.DeviceConduit;
import tango.net.http.HttpConst;

class HttpResponder
{
	this()
	{
		
	}
	
	void[] buf_;
	
	/**
	 * Sets HTTP response status.
	 * If no status is set, defaults to 200 OK.
	 */
	void setStatus(HttpStatus status)
	{
	}
	
	void setHeader(char[] field, char[] value)
	{
		
	}
	
	void sendContent(char[] mimeType, void[][] data, bool compress = false)
	{
		
	}
	
	void sendFile(char[] mimeType, DeviceConduit file, bool compress = false)
	{
		
	}
}