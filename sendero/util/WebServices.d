/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.WebServices;

import tango.net.Uri;
//import tango.net.http.HttpGet;
//import tango.net.http.HttpPost;
import tango.net.http.HttpClient;
import tango.net.http.HttpConst;

import sendero.util.ArrayWriter;

struct Param
{
	char[] name;
	char[] val;
}

class RESTHelper
{
	 static const ubyte unreserved[128] = 
		 [
   	      // 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 0
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  // 1
	         0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  0,  // 2
	         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  0,  0,  0,  // 3
	         0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
	         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  0,  1,  // 5
	         0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  // 4
	         1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0,  0,  0,  1,  0  // 7
	    ];
	static const char[] hexDigits = "0123456789abcdef";
	
	static void uriEncode(void delegate(void[]) consume, char[] src)
	{
		//Uri.encode (consume, src, Uri.IncQueryAll);
		

        char[3] hex;
        uint mark = 0;

        hex[0] = '%';
        foreach (uint i, char c; src)
        {
	       if (c > 127 || !unreserved[c])
           {
	           consume (src[mark..i]);
	           mark = i+1;
	                
	           hex[1] = hexDigits [(c >> 4) & 0x0f];
	           hex[2] = hexDigits [c & 0x0f];
	           consume (hex);
           }
        }

        // add trailing section
        if (mark < src.length)
            consume (src[mark..src.length]);

        return consume;
	}
	
	static char[] createQueryString(char[] url, Param[] queryParams)
	{
		auto res = new ArrayWriter!(char);
		
		createQueryString(cast(void delegate(void[]))&res.append, url, queryParams);
		
		return res.get;
	}
	
	static void createQueryString(void delegate(void[]) consume, char[] url, Param[] queryParams)
	{
		consume(url);
		consume("?");
		bool first = true;
		foreach(p; queryParams)
		{
			if(!first) consume("&");
			consume(p.name);
			consume("=");
			uriEncode(consume, p.val);
			first = false;
		}
	}
	
	static void get(void delegate(void[]) consume, char[] url, Param[] queryParams)
	{
		auto query = createQueryString(url, queryParams);
		scope client = new HttpClient(HttpClient.Get, query);
		client.open;
		client.read(consume);
		delete query;
	}
	
	static void post(void delegate(void[]) consume, char[] url, Param[] queryParams)
	{
		auto query = createQueryString(url, queryParams);
		scope client = new HttpClient(HttpClient.Post, query);
		try{
			client.open;
			auto status = client.getStatus();
	        if (status is HttpResponseCode.OK || 
	            status is HttpResponseCode.Created || 
	            status is HttpResponseCode.Accepted)
	        	client.read(consume);
	        else debug throw new Exception("Http post failed for uri " ~ query);
		}
		finally {
			client.close;
		}
        delete query;
	}
	
	static char[] get(char[] url, Param[] queryParams, uint pageChunk = 16 * 1024)
	{
		auto res = new ArrayWriter!(char)(pageChunk, pageChunk);
		
		get(cast(void delegate(void[]))&res.append, url, queryParams);
		
		return res.get;
		
		/+auto query = createQueryString(url, queryParams);
		auto res = new HttpGet(query);
		return cast(char[])res.read;+/
	}
	
	static char[] post(char[] url, Param[] queryParams, uint pageChunk = 16 * 1024)
	{
		auto res = new ArrayWriter!(char)(pageChunk, pageChunk);
		
		post(cast(void delegate(void[]))&res.append, url, queryParams);
		
		return res.get;
		
	/+	auto query = createQueryString(url, queryParams);
		throw new Exception(query);
		auto post = new HttpPost(query);
		return cast(char[]) post.write;+/
	}
}


unittest
{
	auto q = RESTHelper.createQueryString("http://test.uri/service", [Param("two", "1&2=3?"), Param("one", "hello world")]);
	assert(q == "http://test.uri/service?two=1%262%3d3%3f&one=hello%20world", q);
}
