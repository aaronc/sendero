module sendero.view.TemplateMsgs;

import sendero.view.TemplateEngine;
public import sendero.msg.Msg;

const uint MsgLayout = 1;
const uint ErrorLayout = 2;
const uint SuccessLayout = 3;


interface ISenderoMsgLayoutNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	uint layout();
}

interface ISenderoMsgNode(TemplateCtxt) : ISenderoMsgLayoutNode!(TemplateCtxt)
{
	uint msgid();
}

interface ISenderoMsgsNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	
}

class SenderoMsgsNode(TemplateCtxt) : ISenderoMsgsNode!(TemplateCtxt)
{	
	this(char[][] path)
	{
		this.path = path;
	}
	char[][] path;
	
	void render(TemplateCtxt ctxt, void delegate(void[]) write)
	{
		auto msgMap = ctxt.msgMap;
		foreach(p; path)
		{
			auto msgMap = msgMap.find(path);
		}
		
		foreach(m; msgMap)
		{
			auto handler = getHandler(m.id);
			if(!handler) {
				debug throw new Exception("Message handler not found for " ~ m.toString);
				continue; 
			}
			ctxt.curHandler = handler;
			switch(handler.layout)
			{
			case MsgLayout:
				msgLayout.render(ctxt, write);
				break;
			case ErrorLayout:
				errorLayout.render(ctxt, write);
				break;
			case SuccessLayout:
				successLayout.render(ctxt, write);
				break;
			default:
				auto layout = handler.layout in userLayouts;
				if(!layout) throw new Exception("Unable to find user msg layout");
				layout.render(ctxt, write);
				break;
			}
			ctxt.curHandler = null;
		}
	}
	
	ISenderoMsgNode!(TemplateCtxt)[uint] msgHandlers;
	
	ITemplateNode!(TemplateCtxt) getHandler(uint id)
	{
		auto pm = id in msgHandlers;
		if(pm) {
			return *pm;
		}
		
		pm = id in ctxt.tmpl.msgHandlers;
		if(pm) {
			return *pm;
		}
		
		pm = id in ctxt.tmpl.defaultMsgs;
		if(pm) {
			return *pm;
		}
		
		auto id = Msg.getParentID(m.id);
		if(id) {
			return getHandler(id);
		}
		
		return null;
	}
	
	ITemplateNode!(TemplateCtxt) msgLayout;
	ITemplateNode!(TemplateCtxt) errorLayout;
	ITemplateNode!(TemplateCtxt) successLayout;
	ITemplateNode!(TemplateCtxt)[uint] userLayouts;
	
}

class SenderoMsgLayoutNode(TemplateCtxt) : TemplateContainerNode!(TemplateCtxt), ISenderoMsgLayoutNode!(TemplateCtxt) 
{
	this(uint layout)
	{
		layout_ = layout;
	}
	private uint layout_;
	
	uint layout()
	{
		return layout_;
	}
}

class SenderoMsgNode(TemplateCtxt) : SenderoMsgLayoutNode!(TemplateCtxt), ISenderoMsgNode!(TemplateCtxt) 
{
	this(char[] name, uint layout)
	{
		msgid_ = Msg.getClassID(name);
		super(layout);
	}
	private uint msgid_;
	
	uint msgid()
	{
		return msgid_;
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
		msgDefProcessor.addElementProcessor("d", "msg_layout",
			new SenderoMsgLayoutNodeProcessor!(TemplateCtxt, Template)(childProcessor));
		msgDefProcessor.addElementProcessor("d", "error_layout",
			new SenderoMsgLayoutNodeProcessor!(TemplateCtxt, Template)(childProcessor, "error"));
		msgDefProcessor.addElementProcessor("d", "success_layout",
			new SenderoMsgLayoutNodeProcessor!(TemplateCtxt, Template)(childProcessor, "success"));

	}
	static TemplateCompiler!(TemplateCtxt, Template) msgDefProcessor = null;
	
	static uint getLayoutClassID(char[] cls)
	{
		switch(cls)
		{
		case "error": return ErrorLayout;
		case "msg": return MsgLayout;
		case "success": return SuccessLayout;
		default:
			auto pID = cls in userLayoutClasses;
			if(pID) return *pID;
			synchronized
			{
				auto id = userLayoutClasses.length + 10;
				userLayoutClasses[cls] = id;
				return id;
			}
			break;
		}
	}
	static uint[char[]] userLayoutClasses;
	
	this(INodeProcessor!(TemplateCtxt, Template) childProcessor)
	{
		if(msgDefProcessor) init(childProcessor);
		this.childProcessor = childProcessor;
	}
	
	protected INodeProcessor!(TemplateCtxt, Template) childProcessor;
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		foreach(child; node.children)
		{
			auto n = msgDefProcessor.process(child, tmpl);
			if(n) {
				
			}
		}
		
		return new TemplateDataNode!(TemplateCtxt)(null);
	}
}

class SenderoMsgLayoutNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
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
		
		auto clsId = SenderoMsgDefProcessor!(TemplateCtxt, Template).getLayoutClassID(cls);
		auto container = new SenderoMsgLayoutNode!(TemplateCtxt)(clsId);
		foreach(child; node.children)
		{
			container.children ~= childProcessor(child, tmpl);
		}
		return container;
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
			return null;
		
		auto clsId = SenderoMsgDefProcessor!(TemplateCtxt, Template).getLayoutClassID(cls);
		auto container = new SenderoMsgNode!(TemplateCtxt)(name, clsId);
		foreach(child; node.children)
		{
			container.children ~= childProcessor(child, tmpl);
		}
		return container;
	}
}