module sendero.server.http.HttpServiceProvider;

import sendero.server.model.IHttpRequestHandler;
import sendero.server.http.Http11Parser;
import sendero.server.http.HttpResponder;

class HttpServiceProvider : ITcpServiceProvider
{
	ITcpRequestHandler getRequestHandler()
	{
		
	}
	
	void cleanup(ITcpRequestHandler)
	{
		
	}
}