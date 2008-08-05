/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.http.Request;

public import sendero.http.Params;
public import sendero.http.UrlStack;

enum HttpMethod { Get, Post, Put, Delete };

class Request
{
	/+this(HttpMethod method, UrlStack url, Param[char[]] params)
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
	}+/
	
	this()
	{
		
	}
	
	void parse(HttpMethod method, char[] url, char[] getParams, char[] postParams = null)
	{
		if(method == HttpMethod.Get) {
			this.method = method;
			this.url = UrlStack.parseUrl(url);
			this.params = parseParams(getParams);
		}
		else if(method == HttpMethod.Post) {
			this.method = method;
			this.url = UrlStack.parseUrl(url);
			this.params = parseParams(postParams);
			auto _get_ = parseParams(getParams);
			this.params["_get_"] = Param();
			this.params["_get_"].obj = _get_;
		}
	}
	
	void reset()
	{
		params = null;
		url = null;
		lastToken = null;
		cookies = null;
		ip = null;
	}
	
	Param[char[]] params;
	HttpMethod method;
	UrlStack url;
	char[] lastToken;
	char[][char[]] cookies;
	char[] ip;
}

alias Request Req;