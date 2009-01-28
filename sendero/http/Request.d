/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.http.Request;

public import sendero.http.Params;
public import sendero.http.UrlStack;
public import sendero.http.IRenderable;

import sendero.server.http.model.IHttpRequestHandler;
import sendero.server.http.HttpResponder;

public import tango.net.http.HttpCookies : Cookie;
static import tango.net.http.HttpCookies;
private import tango.net.http.HttpHeaders;

class CookieStack : tango.net.http.HttpCookies.CookieStack
{
	 this (int size)
     {
		 super(size);
     }
	
	Cookie find(char[] name)
	{
		foreach(cookie; this)
		{
			if(cookie.name == name)
				return cookie;
		}
		return null;
	}
}

debug {
	import sendero.Debug;
	
	Logger log;
	static this()
	{
		log = Log.lookup("sendero.http.Request");
	}
}

enum HttpMethod { Get, Post, Put, Delete, Header, Unknown = 0 };

alias void delegate(Request) SenderoRequestHandler;

class Request : HttpResponder, IHttpRequestHandler
{
	this(SenderoRequestHandler handler)
	{
		handler_ = handler;
		cookies = new CookieStack(10);
		cookieParser_ = new tango.net.http.HttpCookies.CookieParser(cookies);
	}
	private SenderoRequestHandler handler_;
	
	void handleRequestLine(HttpRequestLineData reqLine)
	{
		switch(reqLine.method)
		{
	      case "GET": method = HttpMethod.Get; break;
	      case "POST": method = HttpMethod.Post; break;
	      case "PUT": method = HttpMethod.Put; break;
	      case "DELETE": method = HttpMethod.Delete; break;
	      case "HEADER": method = HttpMethod.Header; break;
	      default: method = HttpMethod.Unknown; break;
		}
		uri = reqLine.uri;
		path = UrlStack.parseUrl(reqLine.path);
		fragment = reqLine.fragment;
		params = parseParams(reqLine.queryString, params);
	}
	
	void handleHeader(char[] field, char[] value)
	{
		//headers[field] = value;
		super.handleHeader(field, value);
		if(field == "COOKIE") cookieParser_.parse(value);
	}
	
	void signalFatalError()
	{
		assert(false, "Not implemented");
	}

	SyncTcpResponse processRequest(IHttpRequestData data, ITcpCompletionPort completionPort)
	{
		setCompletionPort(completionPort);
		debug assert(handler_ !is null);
		handler_(this);

		return getSyncResponse;
	}
	
	void parse(HttpMethod method, char[] url, char[] getParams, char[] postParams = null)
	{
		this.method = method;
		this.path = UrlStack.parseUrl(url);
		params = parseParams(getParams, params);
		params = parseParams(postParams, params);
	}
	
	void reset()
	{
 		params = null;
		path = null;
		uri = null;
		fragment = null;
		lastToken = null;
		cookies.reset;
		ip = null;
		//headers = null;
		method = HttpMethod.Unknown;
		super.reset;
	}
	
	IObject params;
	HttpMethod method;
	UrlStack path;
	char[] uri;
	char[] fragment;
	char[] lastToken;
	alias lastToken token;
	//char[][char[]] cookies;
	CookieStack cookies;
	char[] ip;
	//char[][char[]] headers;
	HttpHeaders headers()
	{
		return requestHeaders_;
	}
	
	private tango.net.http.HttpCookies.CookieParser cookieParser_;
	
	void delegate(void[]) getConsumer()
	{
		return cast(void delegate(void[]))&this.write;
	}
	
	void respond(IRenderable r)
	{
		setContentType(r.contentType);
		r.render(cast(void delegate(void[]))&this.write);
	}
	
	void respond(IStream s, char[] contentType)
	{
		setContentType(contentType);
		s.render(cast(void delegate(void[]))&this.write);
	}
	
	void respond(void delegate(void delegate(void[])) stream, char[] contentType = ContentType.TextHtml)
	{
		setContentType(contentType);
		stream(cast(void delegate(void[]))&this.write);
	}
	
	void respond(char[] content, char[] contentType = ContentType.TextHtml)
	{
		sendContent(contentType,content);
	}
	
	alias respond render;
}

alias Request Req;

interface IHttpSet
{
	void httpSet(IObject param, Request req);
}