module sendero.routing.Request;

public import sendero.routing.Common;

class Request
{
	this(HttpMethod method, UrlStack url, Param[char[]] params)
	{
		this.params = params;
		this.method = method;
		this.url = url;
	}
	
	static Request parse(HttpMethod method, char[] url, char[] getParams, char[] postParams = null)
	{
		if(method == HttpMethod.Get) {
			return new Request(method, UrlStack.parseUrl(url), parseParams(getParams));
		}
		else if(method == HttpMethod.Post) {
			auto params = parseParams(postParams);
			auto _get_ = parseParams(getParams);
			params["_get_"] = Param();
			params["_get_"].obj = _get_;
			return new Request(method, UrlStack.parseUrl(url), params);
		}
	}
	
	Param[char[]] params;
	HttpMethod method;
	UrlStack url;
	char[] lastToken;
	char[][char[]] cookies;
	char[] ip;
}


