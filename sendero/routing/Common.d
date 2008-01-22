module sendero.routing.Common;

public import sendero.routing.HTTPRequest;
public import sendero.util.UrlStack;

enum HttpMethod { Get, Post };

interface IFunctionWrapper(Ret, Req)
{
	Ret exec(Req routeParams, void* ptr = null);
}

interface IConverter(T)
{
	bool convert(Param, inout T);
	char[] getFormatString();
}