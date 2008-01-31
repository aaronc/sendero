module sendero.http.Response;

import tango.io.model.IConduit;

struct Response
{
	const char[] TextHtml = "text/html";
	const char[] TextXml = "text/xml";
	const char[] TextJSON = "test/json";
	const char[] AppJS = "application/javascript";
	
	char[] contentType = TextHtml;
	void delegate(void delegate(void[])) contentDelegate;
	void render(void delegate(void[]) consumer)
	{
		consumer("Content-type: ");
		consumer(contentType);
		consumer("\r\n\r\n");
		
		contentDelegate(consumer);
	}
}