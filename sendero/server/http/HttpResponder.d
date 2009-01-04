module sendero.server.http.HttpResponder;

version(Tango_0_99_7) import tango.io.FileConduit;
else import tango.io.device.FileConduit;
import tango.net.http.HttpConst;
import Integer = tango.text.convert.Integer;
import Timestamp = tango.text.convert.TimeStamp;
import tango.time.Clock;

import sendero.server.model.ITcpServiceProvider;

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
		buf_ = "HTTP/1.x";
		buf_ ~= Integer.toString(status.code);
		buf_ ~= " ";
		buf_ ~= status.name;
		buf_ ~= "\r\n";
	}
	
	void setHeader(char[] field, char[] value)
	{
		
	}
	
	void setContentType(char[] mimeType)
	{
		buf_ ~= "Content-Type: ";
		buf_ ~= mimeType;
		buf_ ~= "\r\n";
	}
	
	void sendHeaders()
	{
		
	}
	
	TcpResponse sendContent(char[] mimeType, void[][] data...)
	{
		char[64] tmp;
		auto res = new TcpResponse;
		setStatus(HttpResponses.OK);
		buf_ ~= "Server: Sendero\r\n";
		HttpResponder.setContentType(mimeType);
		buf_ ~= "Date: ";
		buf_ ~= Timestamp.format(tmp, Clock.now);
		buf_ ~= "\r\n";
		buf_ ~= "Connection: keep-alive\r\n";
		size_t len;
		foreach(d; data) len += d.length;
		buf_ ~= "Content-Length: ";
		buf_ ~= Integer.toString(len);
		buf_ ~= "\r\n\r\n";
		res.data ~= buf_;
		res.data ~= data;
		return res;
	}
	
	enum SendFlags { Default = 0x0, ChunkedHeadersSet = 0x1, EndResponse = 0x2 };
	
	
	void sendData(SendFlags flags, void[][] data...)
	{
		
	}
	
	void sendFile(char[] mimeType, FileConduit file, bool compress = false)
	{
		
	}
}