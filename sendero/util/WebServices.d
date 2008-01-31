module sendero.util.WebServices;

import tango.net.Uri;
import tango.net.http.HttpGet;

import sendero.util.ArrayWriter;

struct Param
{
	char[] name;
	char[] val;
}

class RESTHelper
{
	private static char[] uriEncode(char[] src)
	{
		void[] s;
		Uri.encode ((void[] v) {s ~= v;}, src, 0);
		return cast(char[]) s;
	}
	
	static char[] createQueryString(char[] url, Param[] queryParams)
	{
		auto res = new ArrayWriter!(char);
		res ~= url ~ "?";
		foreach(p; queryParams)
		{
			res ~= p.name ~ "=";
			res ~= uriEncode(p.val);
			res ~= "&";
		}
		
		return res.get[0 .. $-1];
	}
	
	static char[] get(char[] url, Param[] queryParams)
	{
		auto query = createQueryString(url, queryParams);
		auto res = new HttpGet(query);
		return cast(char[])res.read;
	}
}


unittest
{
	auto q = RESTHelper.createQueryString("http://test.uri/service", [Param("two", "1&2=3?"), Param("one", "hello world")]);
	assert(q == "http://test.uri/service?two=%31%26%32%3d%33%3f&one=%68%65%6c%6c%6f%20%77%6f%72%6c%64", q);
}
