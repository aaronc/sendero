/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.view.TemplateMsgs;

import sendero.view.TemplateEngine;
import sendero.view.ExecContext;
public import sendero.msg.Msg;

import Util = tango.text.Util;

interface ISenderoMsgNode
{
	char[] msgId();
}

class SenderoRenderMsgsNode(TemplateCtxt) :  ITemplateNode!(TemplateCtxt)
{
	void render(TemplateCtxt tCtxt, Consumer consumer)
	{
		foreach(msgId, msg; tCtxt.msgs)
		{
			auto handler = tCtxt.getMsgHandler(msgId);
			if(handler !is null) {
				if(msg.handle(handler)) msg.render(msg,tCtxt,consumer);
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

class SenderoMsgDefProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	static void init(INodeProcessor!(TemplateCtxt, Template) childProcessor)
	{
		msgDefProcessor = new TemplateCompiler!(TemplateCtxt, Template);
		msgDefProcessor.addElementProcessor("d", "msg",
			new SenderoMsgNodeProcessor!(TemplateCtxt, Template)(childProcessor));
		msgDefProcessor.addElementProcessor("d", "error",
			new SenderoMsgNodeProcessor!(TemplateCtxt, Template)(childProcessor, "error"));
	}
	static TemplateCompiler!(TemplateCtxt, Template) msgDefProcessor = null;
	
	this(INodeProcessor!(TemplateCtxt, Template) childProcessor, bool msgs = false)
	{
		if(msgDefProcessor) init(childProcessor);
		this.childProcessor = childProcessor;
		this.msgs = msgs;
	}
	private bool msgs;
	protected INodeProcessor!(TemplateCtxt, Template) childProcessor;
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		char[] scp;
		char[][] scope_;
		auto def = new MsgDef!(TemplateCtxt); 
		
		if(msgs) {
			getAttr(node, "scope", scp);
			scope_ = Util.split(scp, ".");
		}
		
		//getAttr(node, "msgTag", def.msgTag);
		//getAttr(node, "msgsTag", def.msgsTag);
		
		foreach(child; node.children)
		{
			auto n = msgDefProcessor.process(child, tmpl);
			if(!n)
				continue;
			
			auto mn = cast(ISenderoMsgNode!(TemplateCtxt))(n);
			if(!mn)
				continue;
					
			def.msgHandlers[mn.msgid] = mn;
		}	
		
		if(msgs) {
			return new SenderoMsgsNode!(TemplateCtxt)(scope_, def);
		}
		else {
			tmpl.msgDef = def;
			return new TemplateDataNode!(TemplateCtxt)(null);
		}
	}
}

class SenderoMsgNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{	
	this(INodeProcessor!(TemplateCtxt, Template) childProcessor, char[] cls = null)
	{
		this.childProcessor = childProcessor;
		this.cls = cls;
	}
	private char[] cls;
	
	protected INodeProcessor!(TemplateCtxt, Template) childProcessor;
	
	mixin NestedProcessorCtr!(TemplateCtxt, Template);
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		if(!cls.length) {
			if(!getAttr(node, "class", cls)) {
				cls = "msg";
			}
		}
		
		char[] name;
		if(!getAttr(node, "name", name))
			name = "Error";
		
		auto container = new SenderoMsgNode!(TemplateCtxt)(name, cls);
		foreach(child; node.children)
		{
			container.children ~= childProcessor(child, tmpl);
		}
		return container;
	}
}