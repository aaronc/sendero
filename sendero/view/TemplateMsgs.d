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

abstract class ISenderoMsgNode(TemplateCtxt)
{
	abstract char[] msgId();
	abstract void render(Msg msg, TemplateCtxt tCtxt, Consumer consumer, char[] tag = "div");
}

class SenderoRenderMsgsNode(TemplateCtxt) :  ITemplateNode!(TemplateCtxt)
{
	this(char[] as = "div")
	{
		this.as = as;
	}
	
	char[] as;
	
	protected void doRender(TemplateCtxt tCtxt, Consumer consumer, char[] tag)
	{
		tCtxt.msgMap.read((char[] msgId,Msg msg){
			auto handler = tCtxt.getMsgHandler(msgId);
			if(handler !is null) {
				if(msg.handle(handler)) {
					handler.render(msg,tCtxt,consumer,tag);
					return true;
				}
			}
			else handleUnknown(msg,tCtxt,consumer,tag);
			return false;
		});
	}
	
	protected void handleUnknown(Msg msg, TemplateCtxt tCtxt, Consumer consumer, char[] tag)
	{
		auto handler = tCtxt.getMsgHandler("Unknown");
		if(handler !is null) {
			handler.render(msg,tCtxt,consumer,tag);
		}
		else {
			debug assert(false, "Unable to handle Unknown messages");
			else consumer(`<`,tag,` class="error">An unknown error has occurred.</`,tag,`>`);
		}
	}
	
	final void render(TemplateCtxt tCtxt, Consumer consumer)
	{
		char[] subTag = "div";
		if(as == "ul" || as == "ol") subTag = "li";
		consumer(`<`,as," class = \"msgs\">");		
			doRender(tCtxt,consumer,subTag);
		consumer(`</`,as,">");
	}
}

class SenderoFilteredRenderMsgsNode(TemplateCtxt) :  SenderoRenderMsgsNode!(TemplateCtxt)
{
	this(char[] as)
	{
		super(as);
	}
	
	char[] classname,fieldname;
	
	/+void prehandle(MsgMap map) {
		tCtxt.msgMap.read(classname,fieldname,bool(msgId,msg){
			msg.handle(handler);
			return false;
		});
	}+/
	
	protected void doRender(TemplateCtxt tCtxt, Consumer consumer, char[] tag)
	{
		tCtxt.msgMap.read(classname,fieldname, (char[] msgId,Msg msg) {
			auto handler = tCtxt.getMsgHandler(msgId);
			if(handler !is null) {
				if(msg.handle(this)) {
					handler.render(msg,tCtxt,consumer,tag);
					return true;
				}
			}
			else handleUnknown(msg,tCtxt,consumer,tag);
			return false;
		});
	}
}


class SenderoMsgNode(TemplateCtxt, Template) : ISenderoMsgNode!(TemplateCtxt)
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
	
	final void render(Msg msg, TemplateCtxt tCtxt, Consumer consumer, char[] tag = "div")
	in {
		assert(msg.msgId == this.msgId);
	}
	body {
		debug(SenderoViewDebug) mixin(FailTrace!("SenderoMsgNode.render"));
		
		consumer(`<`,tag,` class="`,cls_,"\">");
			auto parentExecCtxt = tCtxt.execCtxt; 
			scope execCtxt = new ExecContext(parentExecCtxt);
			tCtxt.execCtxt = execCtxt;
			if(msg.classname.length) {
				execCtxt.add("classname",msg.classname);
				if(msg.fieldname.length)
					execCtxt.add("fieldname",msg.fieldname);
			}
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
		consumer(`</`,tag,">");
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
		char[] as;
		if(!getAttr(node,"as",as)) as = "div";
		char[] classname, fieldname;
		if(getAttr(node, "entity", classname)) {
			getAttr(node,"field",fieldname);
			auto res = new SenderoFilteredRenderMsgsNode!(TemplateCtxt)(as);
			res.classname = classname;
			res.fieldname = fieldname;
			if(fieldname.length) tmpl.preHandlers_ = res ~ tmpl.preHandlers_;
			else tmpl.preHandlers_ ~= res;
			return res;
		}
		return new SenderoRenderMsgsNode!(TemplateCtxt)(as);
	}
}