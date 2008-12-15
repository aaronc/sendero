/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.http.Request;

public import sendero.http.Params;
public import sendero.http.UrlStack;
public import sendero.http.IRenderable;
public import sendero.http.Response;

import sendero.server.model.IHttpRequestHandler;

debug {
	import sendero.Debug;
	
	Logger log;
	static this()
	{
		log = Log.lookup("debug.SenderoRouting");
	}
}

enum HttpMethod { Get, Post, Put, Delete, Header, Unknown = 0 };

final class Request : IHttpRequestHandler
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
	
	void handleData(void[][] data)
	{
		
	}

	void[][] processRequest(ITcpCompletionPort completionPort)
	{
		return null;
	}
	
	void parse(HttpMethod method, char[] url, char[] getParams, char[] postParams = null)
	{
		this.method = method;
		this.path = UrlStack.parseUrl(url);
		/+
		if(method == HttpMethod.Get) {
			debug log.trace("Req.parse url:{}, getParams:{}", url, getParams);
			this.params = parseParams(getParams);
		}
		else if(method == HttpMethod.Post) {
			debug log.trace("Req.parse url:{}, getParams:{},postParams:{}", url, getParams, postParams);

			this.params = parseParams(postParams);
			auto _get_ = parseParams(getParams);
			Var _get_Var; set(_get_Var, _get_);
			this.params["@get"] = _get_Var;
		}+/
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
	
	void setResponder(IResponder responder)
	{
		responder_ = responder;
	}
	
	void delegate(void[]) getConsumer()
	{
		assert(responder_, "responder_ is null");
		return &responder_.write;
	}
	
	void setContentType(char[] contentType)
	{
		assert(responder_,  "responder_ is null");
		responder_.setContentType(contentType);
	}
	
	void respond(IRenderable r)
	{
		responder_.setContentType(r.contentType);
		r.render(&responder_.write);
	}
	
	void respond(IStream s, char[] contentType)
	{
		responder_.setContentType(contentType);
		s.render(&responder_.write);
	}
	
	void respond(void delegate(void delegate(void[])) stream, char[] contentType = ContentType.TextHtml)
	{
		responder_.setContentType(contentType);
		stream(&responder_.write);
	}
	
	void respond(char[] content, char[] contentType = ContentType.TextHtml)
	{
		responder_.setContentType(contentType);
		responder_.write(content);
	}
	
	void setCookie(char[] name, char[] value)
	{
		responder_.setCookie(name, value);
	}
	
	void setCookie(Cookie cookie)
	{
		responder_.setCookie(cookie);
	}
	
	alias respond render;
	
	private:
		IResponder responder_;
}

alias Request Req;

interface IHttpSet
{
	void httpSet(IObject param, Request req);
}