/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.view.TemplateMsgs;

import sendero.view.TemplateEngine;
import sendero.view.ExecContext;
import sendero.msg.Msg;

import Text = tango.text.Util;

debug {
	import sendero.Debug;
	
	Logger log;
	static this()
	{
		log = Log.lookup("sendero.view.TemplateMsgs");
	}
}

interface ISenderoMsgNode
{
	char[] msgId();
}

class SenderoRenderMsgsNode(TemplateCtxt) :  ITemplateNode!(TemplateCtxt)
{
	void render(TemplateCtxt tCtxt, Consumer consumer)
	{
		foreach(msgId, msg; tCtxt.msgMap)
		{
			auto handler = tCtxt.getMsgHandler(msgId);
			if(handler !is null) {
				if(msg.handle(handler)) handler.render(msg,tCtxt,consumer);
			}
		}
	}
}

class SenderoMsgNode(TemplateCtxt, Template) : ISenderoMsgNode
{	
	private this(
			char[] msgId, char[] cls, char[][] params,
			XmlNode node, Template tmpl, INodeProcessor!(TemplateCtxt, Template) proc)
	{
		msgId_ = msgId;
		cls_ = cls;
		params_ = params;
		foreach(child; node.children)
		{
			auto node = proc(child, tmpl);
			if(node !is null) children ~= node; 
		}
	}
	
	void render(Msg msg, TemplateCtxt tCtxt, Consumer consumer)
	in {
		assert(msg.msgId == this.msgId);
	}
	body {
		debug(SenderoViewDebug) mixin(FailTrace!("SenderoMsgNode.render"));
		
		consumer(`<div class="`,cls_,`">`);
			auto parentExecCtxt = tCtxt.execCtxt; 
			scope execCtxt = new ExecContext(parentExecCtxt);
			tCtxt.execCtxt = execCtxt;
			size_t mLen = msg.params.length;
			size_t pLen = params.length;
			for(size_t i = 0; i < mLen && i < pLen; ++i)
			{
				execCtxt[params[i]] = msg.params[i];
			}
			foreach(child; children)
			{
				child.render(tCtxt, consumer);
			}
			tCtxt.execCtxt = parentExecCtxt;
		consumer(`</div>`);
	}
	
	ITemplateNode!(TemplateCtxt)[] children;
	
	final char[] msgId()
	{
		return msgId_;
	}
	private char[] msgId_;
	
	final char[] cls()
	{
		return cls_;
	}
	private char[] cls_;
	
	final char[][] params()
	{
		return params_;
	}
	private char[][] params_;
}

class SenderoMsgNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	this(char[] defaultCls, INodeProcessor!(TemplateCtxt, Template) childProcessor)
	{
		defaultCls_ = defaultCls;
		this.childProcessor = childProcessor;
	}
	
	private INodeProcessor!(TemplateCtxt, Template) childProcessor;
	private char[] defaultCls_ = "msg";
	
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	in {
		assert(node.type == XmlNodeType.Element);
	}
	body {
		debug(SenderoViewDebug) mixin(FailTrace!("SenderoMsgNodeProcessor.process"));
		debug log.trace("Processing msg node");
		
		char[] msgId;
		if(!getAttr(node, "id", msgId))
			return null;
		
		
		char[] proto;
		char[][] params;
		if(getAttr(node, "params", proto))
		{
			 params = Text.split(proto, ",");
			 for(size_t i = 0; i < params.length; ++i)
			 {
				 params[i] = Text.trim(params[i]);
			 }
		}
		
		char[] cls;
		if(!getAttr(node, "class", cls))
			cls = defaultCls_;
		
		auto msgNode = new SenderoMsgNode!(TemplateCtxt, Template)
			(msgId,cls,params,node,tmpl,childProcessor);
		
		tmpl.msgHandlers_[msgId] = msgNode;
		
		return null;
	}
}

class SenderoRenderMsgsNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	in {
		assert(node.type == XmlNodeType.Element);
	}
	body {
		return new SenderoRenderMsgsNode!(TemplateCtxt);
	}
}