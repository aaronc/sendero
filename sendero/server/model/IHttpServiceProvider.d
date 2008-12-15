module sendero.server.model.IHttpServiceProvider;

public import sendero.server.model.IHttpRequestHandler;

interface IHttpServiceProvider
{
	IHttpRequestHandler handleHttpRequest(void[][] data);
}