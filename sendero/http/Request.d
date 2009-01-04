/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.http.Request;

public import sendero.http.Params;
public import sendero.http.UrlStack;
public import sendero.http.IRenderable;

import sendero.server.model.IHttpRequestHandler;
import sendero.server.http.HttpResponder;

debug {
	import sendero.Debug;
	
	Logger log;
	static this()
	{
		log = Log.lookup("debug.SenderoRouting");
	}
}

enum HttpMethod { Get, Post, Put, Delete, Header, Unknown = 0 };

class Request : HttpResponder, IHttpRequestHandler
{
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
		headers[field] = value;
		if(field == "COOKIE") cookies = parseCookies(value);
	}
	
	void signalFatalError()
	{
		assert(false, "Not implemented");
	}

	SyncTcpResponse processRequest(IHttpRequestData data, ITcpCompletionPort completionPort)
	{
		//completionPort.sendResponseData("Hello world")
		//return null;
		char[] res = "<html><head><title>Sendero Server Test</title></head><body>";
		res ~= "<h1>Hello Sendero HTTP Server World</h1>";
		res ~= "<p>";
		res ~= "URI:" ~ uri;
		res ~= "</p><p>";
		res ~= "Path:" ~ path.origUrl;
		res ~= "</p>";
		res ~= "<table>";
		foreach(key,val;headers)
		{
			res ~= "<tr>";
			res ~= "<td>" ~ key ~ "</td>";
			res ~= "<td>" ~ val ~ "</td>";
			res ~= "</tr>";
		}
		res ~= "</table>";
		res ~= "</body></html>";
		
		setCookie("Test","1");
		//setCookie(new Cookie("Test2","2"));
		
		sendContent("text/html",res);
		
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
		cookies = null;
		ip = null;
		headers = null;
		method = HttpMethod.Unknown;
	}
	
	IObject params;
	HttpMethod method;
	UrlStack path;
	char[] uri;
	char[] fragment;
	char[] lastToken;
	char[][char[]] cookies;
	char[] ip;
	char[][char[]] headers;
	
	void delegate(void[]) getConsumer()
	{
		//assert(responder_, "responder_ is null");
		//return &responder_.write;
		return cast(void delegate(void[]))&this.write;
	}
	
	/+void setContentType(char[] contentType)
	{
		//assert(responder_,  "responder_ is null");
		responder_.setContentType(contentType);
	}+/
	
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
		/+responder_.setContentType(contentType);
		responder_.write(content);+/
		sendContent(contentType,content);
	}
	
	alias respond render;
}

alias Request Req;

interface IHttpSet
{
	void httpSet(IObject param, Request req);
}