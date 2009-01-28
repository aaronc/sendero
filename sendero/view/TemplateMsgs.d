/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.view.TemplateMsgs;

import sendero.view.TemplateEngine;
public import sendero.msg.Msg;

import Util = tango.text.Util;

interface ISenderoMsgNode(TemplateCtxt): ITemplateNode!(TemplateCtxt)
{
	uint msgid();
	char[] cls();
}

interface ISenderoMsgsNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	
}

class MsgDef(TemplateCtxt)
{
	ISenderoMsgNode!(TemplateCtxt)[uint] msgHandlers;
	char[] msgsTag = "div";
	char[] msgTag = "div";
}

class SenderoMsgsNode(TemplateCtxt) : ISenderoMsgsNode!(TemplateCtxt)
{	
	this(char[][] path, MsgDef!(TemplateCtxt) def)
	{
		this.path = path;
		this.def = def;
	}
	
	char[][] path;
	MsgDef!(TemplateCtxt) def;
	
	void render(TemplateCtxt ctxt, void delegate(void[]) write)
	{
		ISenderoMsgNode!(TemplateCtxt) getHandler(uint id)
		{
			auto pm = id in def.msgHandlers;
			if(pm) {
				return *pm;
			}
			
			pm = id in ctxt.tmpl.msgDef.msgHandlers;
			if(pm) {
				return *pm;
			}
			
			pm = id in ctxt.tmpl.defaultMsgDef.msgHandlers;
			if(pm) {
				return *pm;
			}
			
			id = Msg.getParentID(id);
			if(id) {
				return getHandler(id);
			}
			
			return null;
		}
		
		auto msgMap = ctxt.msgMap;
		foreach(p; path)
		{
			msgMap = msgMap.find(p).map;
		}
		
		if(def.msgsTag)
		{
			write("<");
			write(def.msgsTag);
			write(">");
		}
		
		foreach(m; msgMap)
		{
			auto handler = getHandler(m.id);
			if(!handler) {
				debug throw new Exception("Message handler not found for " ~ m.toString);
				continue; 
			}
			if(def.msgTag)
			{
				write("<");
				write(def.msgTag);
				
				auto msgCls = handler.cls;
				if(msgCls) {
					write(" class='");
					write(msgCls);
					write("'");
				}
				write(">");
			}
			
			handler.render(ctxt, write);
			
			if(def.msgTag)
			{
				write("</");
				write(def.msgTag);
				write(">");
			}
		}
		
		if(def.msgsTag)
		{
			write("</");
			write(def.msgsTag);
			write(">");
		}
	}	
}

class SenderoMsgNode(TemplateCtxt) : TemplateContainerNode!(TemplateCtxt), ISenderoMsgNode!(TemplateCtxt) 
{
	this(char[] msgId, char[] cls, char[][] params)
	{
		msgId_ = msgId;
		cls_ = cls;
		params_ params;
	}
	
	void render(TemplateCtxt tCtxt, Consumer consumer)
	{
		debug(SenderoViewDebug) mixin(FailTrace!("SenderoMsgNode.render"));
		
		consumer(`<div class="`,cls_,`">`);
			auto parentExecCtxt = tCtxt.execCtxt; 
			scope execCtxt = new ExecContext(parentExecCtxt);
			tCtxt.execCtxt = execCtxt;
			for(int i = 0; i < paramNames.length && i < params.length; ++i)
			{
				execCtxt[paramNames[i]] = params[i];
			}
			super.render(ctxt,consumer);
			tCtxt.execCtxt = parentExecCtxt;
		consumer(`</div>`);
	}
	
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


class SenderoMsgNode(TemplateCtxt) : TemplateContainerNode!(TemplateCtxt), ISenderoMsgNode!(TemplateCtxt) 
{
	this(char[] name, char[] cls)
	{
		msgid_ = Msg.getClassID(name);
		cls_ = cls;
	}
	private uint msgid_;
	private char[] cls_;
	
	uint msgid()
	{
		return msgid_;
	}
	
	char[] cls()
	{
		return cls_;
	}
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
		msgDefProcessor.addElementProcessor("d", "success",
			new SenderoMsgNodeProcessor!(TemplateCtxt, Template)(childProcessor, "success"));
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