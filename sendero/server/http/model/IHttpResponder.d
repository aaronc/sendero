module sendero.server.http.model.IHttpResponder;

public import tango.io.model.IConduit;

interface IHttpResponder
{
	OutputStream getOutputStream();
	
	void sendHeaders();
	void sendData(bool finish, void[][] data...);
	
	void sendContent(char[] mimeType, void[][] data...);
	
	/**
	 * Sets HTTP response status.
	 * If no status is set, defaults to 200 OK.
	 */
	void setStatus(HttpStatus status)
	
	void setHeader(HttpHeaderName field, char[] value);
	
	void setHeader(char[] field, char[] value);
	
	void setHeader(HttpHeaderName field, int value);
	
	void setHeader(char[] field, int value);
	
	void setHeader(HttpHeaderName field, Time value);
	
	void setHeader(char[] field, Time value);
	
	void setContentType(char[] mimeType);
	
	void setContentLength(size_t contentLength);
	
	void setChunked();
	
	void setCookie(char[] name, char[] value);
	
	void setCookie(Cookie cookie);
}