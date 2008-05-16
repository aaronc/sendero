/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.view.SenderoTemplateInternals;

import sendero.view.TemplateEngine;
import sendero.xml.XmlNode;
import sendero.vm.ExecutionContext;
import sendero.vm.LocalText;
import sendero.util.StringCharIterator;
import sendero.util.ArrayWriter;
import sendero.util.collection.NestedMap;
import sendero.Exception;

import tango.group.file;
import tango.text.Util;
import Integer = tango.text.convert.Integer;
debug import tango.io.Stdout;

version(SenderoTemplateMsgs)
{
	public import sendero.msg.Msg;
	import sendero.view.TemplateMsgs;
}

class AbstractSenderoTemplateContext(ExecCtxt, TemplateCtxt, Template) : DefaultTemplateContext!(TemplateCtxt, Template)
{
	this(Template tmpl, Locale locale)
	{
		super(tmpl);
		execCtxt = new ExecCtxt(locale);
		version(SenderoTemplateMsgs)
		{
			msgMap = Msg.read;
			curMsgHandler = null;
		}
	}
	
	version(SenderoTemplateMsgs)
	{
		MsgMap msgMap;
		ITemplateNode!(TemplateCtxt) curMsgHandler;
	}
	
	ExecCtxt execCtxt;
	Template[] parentTemplates;
	SenderoBlockContainer!(TemplateCtxt) curBlock;
	
	void inherit(Template tmpl)
	{
		execCtxt.runtimeImports ~= tmpl.functionCtxt;
		parentTemplates ~= tmpl;
	}
	
	void opIndexAssign(T)(T t, char[] name)
	{
		execCtxt.addVar(name, t);
	}
	
	void use(T)(T t)
	{
		execCtxt.addVarAsRoot(t);
	}
	
	version(SenderoTemplateMsgs)
	{
		char[][char[]] prerenderedMsgs;
	}
}

class AbstractSenderoTemplate(TemplateCtxt, Template) : DefaultTemplate!(TemplateCtxt, Template, Locale)
{
	static this()
	{
		if(!engine)
			init;
	}
	
	static void init()
	{
		engine = new TemplateCompiler!(TemplateCtxt, Template);
		engine.defaultDataProcessor = new SenderoDataNodeProc!(TemplateCtxt, Template);
		engine.defaultElemProcessor = new SenderoElemProcessor!(TemplateCtxt, Template)(engine);
		engine.addElementProcessor("d", "", new NullNodeProcessor!(TemplateCtxt, Template));
		engine.addElementProcessor("d", "for", new SenderoForNodeProc!(TemplateCtxt, Template)(engine));
		engine.addElementProcessor("xi", "include", new XIIncludeProcessor!(TemplateCtxt, Template));
		auto blockProc = new SenderoBlockNodeProcessor!(TemplateCtxt, Template)(engine);
		engine.addElementProcessor("d", "block", blockProc);
		engine.addAttributeProcessor("d", "block", blockProc);
		engine.addElementProcessor("d", "extends", new SenderoExtendsNodeProcessor!(TemplateCtxt, Template)(engine));
		engine.addElementProcessor("d", "super", new SenderoSuperNodeProcessor!(TemplateCtxt, Template));
		engine.addElementProcessor("d", "choose", new SenderoChooseNodeProcessor!(TemplateCtxt, Template)(engine));
		engine.addElementProcessor("d", "if", new SenderoIfNodeProcessor!(TemplateCtxt, Template)(engine));
		engine.addElementProcessor("d", "def", new SenderoDefNodeProcessor!(TemplateCtxt, Template)(engine));
		engine.addElementProcessor("d", "static", new SenderoStaticNodeProcessor!(TemplateCtxt, Template)(engine));
		version(SenderoTemplateMsgs)
		{
			//engine.addElementProcessor("d", "msgs", new SenderoMsgsNodeProcessor!(TemplateCtxt, Template)(engine));
			engine.addElementProcessor("d", "msgdef", new SenderoMsgDefProcessor!(TemplateCtxt, Template)(engine));
		}
	}
	
	protected static TemplateCompiler!(TemplateCtxt, Template) engine;
	
	static Template compile(char[] src, Locale locale)
	{
		auto tmpl = new Template;
		tmpl.staticCtxt = new TemplateCtxt(tmpl, locale);
		engine.compile(src, tmpl);
		tmpl.staticCtxt = null;
		return tmpl;
	}
	
	private static struct TemplateCache
	{
		Template templ;
		FilePath path;
		Time lastModified;
	}
	
	private static char[] searchPath;
	
	private static TemplateCache[char[]] cache;
	static Template getTemplate(char[] path, Locale locale)
	{
		auto pt = (searchPath ~ path in cache);
		if(!pt) {
			auto fp = new FilePath(searchPath ~ path);
			scope f = new File(fp);
			if(!f) throw new Exception("Template not found");
			auto txt = cast(char[])f.read;
			auto templ = Template.compile(txt, locale);
			
			TemplateCache templCache;
			templCache.templ = templ;
			templCache.path = fp;
			templCache.lastModified = fp.modified;		
			cache[path] = templCache;
			
			return templ;
		}
		
		with(*pt) {
			if(lastModified != path.modified) {
				scope f = new File(path);
				auto txt = cast(char[])f.read;
				templ = Template.compile(txt, locale);
				lastModified = path.modified;
			}
			return templ;
		}
	}
	
	static TemplateCtxt get(char[] path, Locale locale)
	{
		return getTemplate(path, locale).createInstance(locale);
	}
	
	static void setSearchPath(char[] path)
	{
		searchPath = path;
	}
	
	this()
	{
		functionCtxt = new FunctionBindingContext;
	}
	
	FunctionBindingContext functionCtxt;	
	SenderoBlockContainer!(TemplateCtxt)[char[]] blocks;
	TemplateCtxt staticCtxt;
	
	void render(TemplateCtxt templCtxt, Consumer consumer)
	{
		rootNode.render(templCtxt, consumer);
	}
	
	version(SenderoTemplateMsgs)
	{
		static void importGlobalMsgs(char[] filepath, Locale locale)
		{
			auto t = getTemplate(filepath, locale);
			/*foreach(id, msg; t.msgs)
				defaultMsgs[id] = msg;*/
			defaultMsgDef = t.msgDef;
		}
		
		//static ITemplateNode!(TemplateCtxt)[uint] defaultMsgs;
		//ITemplateNode!(TemplateCtxt)[uint] msgs;
		static MsgDef!(TemplateCtxt) defaultMsgDef;
		MsgDef!(TemplateCtxt) msgDef;
		//ITemplateNode!(TemplateCtxt)[uint] msgs;
		
		//ISenderoMsgsNode!(TemplateCtxt)[char[]] msgScopes;
/+		NestedMap!(ISenderoMsgsNode) msgScopes;
		
		void routeMsgs(MsgMap msgMap)
		{
			auto sItr = msgScopes.getIterator;
			auto mItr =  msgMap.getIterator;
			
			while(sItr() && mItr()) {
				auto res = strcmp(sItr.key, mItr.key);
				if(res == 0) {
					sItr++;
					mItr++;				
					continue;
				}
				while(sItr()) {
					sItr++;
					res = strcmp(sItr.key, mItr.key);
					if(res == 0) {
						break;
					}
					else if(res > 0) {
						assert(false, "Handle");
						mItr++;
						break;
					}
				}
			}
			while(mItr()) {
				assert(false, "Handle");
				mItr++;
			}
		}+/
	}
}

class SenderoElemProcessor(TemplateCtxt, Template) : DefaultElemProcessor!(TemplateCtxt, Template)
{
	this(INodeProcessor!(TemplateCtxt, Template) childProcessor)
	{
		super(childProcessor);
	}
	
	protected ITemplateNode!(TemplateCtxt) processAttr(XmlNode attr, Template tmpl)
	{
		auto msg = parseMessage(attr.rawValue, tmpl.functionCtxt);
		if(msg.params.length) {
			return new SenderoAttributeNode!(TemplateCtxt)(attr.prefix, attr.localName, msg);
		}
		else {
			return new TemplateAttributeNode!(TemplateCtxt)(attr.prefix, attr.localName, attr.rawValue);
		}
	}
}

class SenderoAttributeNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(char[] prefix, char[] localName, IMessage msg)
	{
		if(prefix.length)
			name = prefix ~ ":" ~ localName;
		else
			name = localName;
		this.msg = msg;
	}
	
	char[] name;
	IMessage msg;
	
	void render(TemplateCtxt ctxt, Consumer consumer)
	{
		consumer(name ~ "=" ~ "\"" ~ msg.exec(ctxt.execCtxt) ~ "\"");
	}
}


class SenderoDataNodeProc(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Data);
		
		if(node.type != XmlNodeType.Data)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		auto msg = parseMessage(node.rawValue, tmpl.functionCtxt);
		if(msg.params.length) {
			return new SenderoDataNode!(TemplateCtxt)(msg);
		}
		else {
			return new TemplateDataNode!(TemplateCtxt)(node.rawValue);
		}
	}
}

class SenderoDataNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(IMessage msg)
	{
		this.msg = msg;
	}
	
	IMessage msg;
	
	void render(TemplateCtxt ctxt, Consumer consumer)
	{
		consumer(cast(char[])msg.exec(ctxt.execCtxt));
	}
}

class SenderoForNodeProc(TemplateCtxt, Template) : DefaultElemProcessor!(TemplateCtxt, Template)
{
	this(INodeProcessor!(TemplateCtxt, Template) childProcessor)
	{
		super(childProcessor);
	}
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{		
		char[] each;
		if(!getAttr(node, "each", each))
		{
			return super.process(node, tmpl);
		}
		
		char[] localVarName1, localVarName2;
		VarPath varName;
		
		auto p = new StringCharIterator!(char)(each);
		
		if(p[0] != '$') return super.process(node, tmpl);
		++p;
		while(p[0] != ',' && p[0] != ' ') {
			++p; 
		}
		
		localVarName1 ~= p.randomAccessSlice(1, p.location);
		
		p.eatSpace;
		if(p[0] == ',') {
			++p;
			p.eatSpace;
			if(p[0] != '$') return super.process(node, tmpl);
			++p;
			auto loc = p.location;
			while(p[0] != ' ') {
				++p; 
			}
			
			//action.action = XmlTemplateActionType.AssocFor;
			localVarName2 ~= p.randomAccessSlice(loc, p.location);
		}
		
		if(!p.forwardLocate('i')) return super.process(node, tmpl);
		if(p[0 .. 3] != "in ") return super.process(node, tmpl);
		
		p += 3;
		auto loc = p.location;
		auto e = p.randomAccessSlice(loc, p.length);
		
		Expression expr;
		parseExpression(e, expr, tmpl.functionCtxt);
		
		char[] sep;
		//debug if(getAttr(node, "sep", sep)) assert(false, "List For not implemented yet");
		//debug if(localVarName2.length) assert(false, "Assoc For not implemented yet");
		
		auto forNode = new SenderoForNode!(TemplateCtxt)(expr, localVarName1);
		
		foreach(child; node.children)
		{
			forNode.children ~= childProcessor(child, tmpl);
		}
		
		return forNode;
	}
}

class SenderoForNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(Expression expr, char[] localVarName)
	{
		this.expr = expr;
		this.localVarName = localVarName;
	}
	
	protected Expression expr;
	protected char[] localVarName;
	ITemplateNode!(TemplateCtxt)[] children;
	
	void render(TemplateCtxt ctxt, Consumer res)
	{
		auto var = expr.exec(ctxt.execCtxt);
		if(var.type != VarT.Array) return;
		
		uint i = 0; uint last = var.arrayBinding.length - 1;
	
		scope localCtxt = new ExecutionContext(ctxt.execCtxt);
		auto curCtxt = ctxt.execCtxt;
		ctxt.execCtxt = localCtxt;
		
		foreach(v; var.arrayBinding)
		{
			localCtxt.addVar(localVarName, v);
			localCtxt.addVar("__loopN__", i);
			if(i == last) localCtxt.addVar("__loopLast__", true);
			
			foreach(child; children)
				child.render(ctxt, res);
			
			++i;
		}
		
		ctxt.execCtxt = curCtxt;
	}
}

class XIIncludeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		if(node.type != XmlNodeType.Element)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		char[] href;
		if(!getAttr(node, "href", href))
		{
			return new TemplateDataNode!(TemplateCtxt)(null);
		}
		
		auto msg = parseMessage(href, tmpl.functionCtxt);
		return new XIIncludeExprNode!(TemplateCtxt)(msg);
	}
}

class XIIncludeExprNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(IMessage msg)
	{
		this.expr = msg;
	}
	protected IMessage expr;
	
	void render(TemplateCtxt ctxt, Consumer res)
	{
		auto locale = ctxt.execCtxt.locale;
		auto path = expr.exec(ctxt.execCtxt);
		auto templ = ctxt.tmpl.getTemplate(path, locale);
		if(!templ) return;
		
		ctxt.execCtxt.runtimeImports ~= templ.functionCtxt;
		templ.render(ctxt, res);
	}
}

class SenderoBlockNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template), IAttributeProcessor!(TemplateCtxt, Template)
{
	mixin NestedProcessorCtr!(TemplateCtxt, Template);
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		if(node.type != XmlNodeType.Element)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		char[] name;
		if(!getAttr(node, "name", name))
		{
			return new TemplateDataNode!(TemplateCtxt)(null);
		}
		
		auto block = new SenderoBlockContainer!(TemplateCtxt)(name);
		auto blockAction = new SenderoBlockAction!(TemplateCtxt)(name);
		
		foreach(child; node.children)
		{
			block.children ~= childProcessor(child, tmpl);
		}
		
		tmpl.blocks[name] = block;
		
		return blockAction;
	}
	
	ITemplateNode!(TemplateCtxt) processAttr(XmlNode attr, Template tmpl)
	{
		debug assert(attr.type == XmlNodeType.Attribute);
		
		if(attr.type != XmlNodeType.Attribute)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		auto name = attr.rawValue;
		auto block = new SenderoBlockContainer!(TemplateCtxt)(name);
		auto blockAction = new SenderoBlockAction!(TemplateCtxt)(name);
		
		auto node = attr.parent;
		attr.remove;
		
		block.children ~= childProcessor(node, tmpl);
		
		tmpl.blocks[name] = block;
		
		return blockAction;
	}
}

class SenderoBlockContainer(TemplateCtxt) : TemplateContainerNode!(TemplateCtxt)
{
	this(char[] name)
	{
		this.name = name;
	}
	char[] name;
	
	void render(TemplateCtxt ctxt, Consumer consumer)
	{
		auto lastBlock = ctxt.curBlock;
		ctxt.curBlock = this;
		super.render(ctxt, consumer);
		ctxt.curBlock = lastBlock;
	}
}

class SenderoBlockAction(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(char[] name)
	{
		this.name = name;
	}
	private char[] name;
	
	void render(TemplateCtxt ctxt, Consumer consumer)
	{
		auto pBlock = name in ctxt.tmpl.blocks;
		if(pBlock) {
			pBlock.render(ctxt, consumer);
			return;
		}
		
		foreach(t; ctxt.parentTemplates)
		{
			pBlock = name in t.blocks;
			if(pBlock) {
				pBlock.render(ctxt, consumer);
				return;
			}
		}
	}
}

class SenderoExtendsNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	mixin NestedProcessorCtr!(TemplateCtxt, Template);
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		if(node.type != XmlNodeType.Element)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		char[] href;
		if(!getAttr(node, "href", href))
		{
			return new TemplateDataNode!(TemplateCtxt)(null);
		}
		auto msg = parseMessage(href, tmpl.functionCtxt);
		
		auto extends = new SenderoExtendsNode!(TemplateCtxt)(msg);
		
		foreach(child; node.children)
		{
			if(child.prefix == "d" && child.localName == "block")
			{
				childProcessor(child, tmpl);
			}
		}		
		
		return extends;
	}
}

class SenderoExtendsNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(IMessage msg)
	{
		this.expr = msg;
	}
	protected IMessage expr;
	
	void render(TemplateCtxt ctxt, Consumer res)
	{
		auto locale = ctxt.execCtxt.locale;
		auto path = expr.exec(ctxt.execCtxt);
		auto templ = ctxt.tmpl.getTemplate(path, locale);
		if(!templ) return;
		
		ctxt.inherit(templ);
		templ.render(ctxt, res);
	}
}

class SenderoSuperNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		if(node.type != XmlNodeType.Element)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		return new SenderoSuperNode!(TemplateCtxt);
	}
}

class SenderoSuperNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{	
	void render(TemplateCtxt ctxt, Consumer consumer)
	{
		if(!ctxt.curBlock)
			return;
		auto name = ctxt.curBlock.name;
		
		auto firstBlock = name in ctxt.tmpl.blocks;
		if(firstBlock && *firstBlock != ctxt.curBlock) firstBlock = null;
		if(firstBlock) {
			foreach(t; ctxt.parentTemplates)
			{
				auto pBlock = name in t.blocks;
				if(pBlock) {
					pBlock.render(ctxt, consumer);
					return;
				}
			}
		}
		else
		{
			foreach(t; ctxt.parentTemplates)
			{
				if(!firstBlock)
				{
					firstBlock = name in t.blocks;
					if(firstBlock && *firstBlock != ctxt.curBlock) firstBlock = null;
				}
				else
				{
					auto pBlock = name in t.blocks;
					if(pBlock) {
						pBlock.render(ctxt, consumer);
						return;
					}
				}
				
			}
		}
	}
}

class SenderoChooseNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	mixin NestedProcessorCtr!(TemplateCtxt, Template);
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		if(node.type != XmlNodeType.Element)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		char[] e;
		if(!getAttr(node, "expr", e))
		{
			return new TemplateDataNode!(TemplateCtxt)(null);
		}
		Expression expr;
		parseExpression(e, expr, tmpl.functionCtxt);
		
		auto choose = new SenderoChooseNode!(TemplateCtxt)(expr);
		
		foreach(child; node.children)
		{
			if(child.prefix == "d")
			{
				if(child.localName == "when")
				{
					char[] val;
					if(!getAttr(child, "val", val))
						continue;
					
					Choice!(TemplateCtxt) choice;
					
					choice.val = parseChoiceLiteral(val);
					choice.node = TemplateContainerNode!(TemplateCtxt).createFromChildren(child, tmpl, childProcessor);
					
					choose.choices ~= choice;
				}
				else if(child.localName == "otherwise")
				{
					choose.otherwise = TemplateContainerNode!(TemplateCtxt).createFromChildren(child, tmpl, childProcessor);
				}
			}
		}
		
		return choose;
	}
}

Var parseChoiceLiteral(char[] txt)
{
	Var res;
	switch(txt)
	{
	case "true": res.set(true); break;
	case "false": res.set(false); break;
	default:
		bool num = true;
		foreach(c; txt)
		{
			if(c < 30 || c > 39) {
				num = false;
				break;
			}
		}
		
		if(num) res.set(Integer.parse(txt));
		else res.set(txt);
		return res;
	}
}

struct Choice(TemplateCtxt)
{
	ITemplateNode!(TemplateCtxt) node;
	Var val;
}

class SenderoChooseNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(Expression expr)
	{
		this.expr = expr;
	}
	
	Expression expr;
	
	Choice!(TemplateCtxt)[] choices;
	ITemplateNode!(TemplateCtxt) otherwise;
	
	void render(TemplateCtxt ctxt, Consumer consumer)
	{
		auto val = expr.exec(ctxt.execCtxt);
		
		foreach(c; choices)
		{
			if(val == c.val)
			{
				c.node.render(ctxt, consumer);
				return;
			}
		}
		
		if(otherwise) otherwise.render(ctxt, consumer);
	}
}

class SenderoIfNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	mixin NestedProcessorCtr!(TemplateCtxt, Template);
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		if(node.type != XmlNodeType.Element)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		char[] e;
		if(!getAttr(node, "test", e))
		{
			return new TemplateDataNode!(TemplateCtxt)(null);
		}
		Expression expr;
		parseExpression(e, expr, tmpl.functionCtxt);
		
		auto ifNode = new SenderoIfNode!(TemplateCtxt)(expr);
		
		foreach(child; node.children)
		{
			ifNode.children ~= childProcessor(child, tmpl);
		}
		
		node = node.nextSibling;
		while(node && node.prefix == "d" && node.localName == "elif")
		{
			if(getAttr(node, "test", e))
			{
				Elif!(TemplateCtxt) elif;
				parseExpression(e, elif.expr, tmpl.functionCtxt);
				elif.node = TemplateContainerNode!(TemplateCtxt).createFromChildren(node, tmpl, childProcessor);
				ifNode.elifs ~= elif;
			}
			
			node = node.nextSibling;
		}
		
		if(node && node.prefix == "d" && node.localName == "else")
		{
			ifNode.otherwise = TemplateContainerNode!(TemplateCtxt).createFromChildren(node, tmpl, childProcessor);
		}
		
		return ifNode;
	}
}

bool templateBool(Var var)
{
	switch(var.type)
	{
	case VarT.Null:
		return false;
	case VarT.Bool:
		return var.bool_;
	case VarT.Long:
		return var.long_ >= 1 ? true : false;
	case VarT.Double:
		return var.double_ >= 1 ? true : false;
	case VarT.Object:
		return var.objBinding.length >= 1 ? true : false;
	case VarT.String:
		return var.string_.length >= 1 ? true : false;
	case VarT.Array:
		return var.arrayBinding.length >= 1 ? true : false;
	default:
		return false;
	}
}

private struct Elif(TemplateCtxt)
{
	ITemplateNode!(TemplateCtxt) node;
	Expression expr;
}

class SenderoIfNode(TemplateCtxt) : TemplateContainerNode!(TemplateCtxt)
{
	this(Expression expr)
	{
		this.expr = expr;
	}
	Expression expr;
	
	
	Elif!(TemplateCtxt)[] elifs;
	ITemplateNode!(TemplateCtxt) otherwise;
	
	void render(TemplateCtxt ctxt, Consumer consumer)
	{
		auto var = expr.exec(ctxt.execCtxt);
		if(templateBool(var))
		{
			return super.render(ctxt, consumer);
		}
		
		foreach(elif; elifs)
		{
			var = elif.expr.exec(ctxt.execCtxt);
			if(templateBool(var))
			{
				return elif.node.render(ctxt, consumer);
			}
		}
		
		if(otherwise) return otherwise.render(ctxt, consumer);
	}
}

class SenderoDefNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	mixin NestedProcessorCtr!(TemplateCtxt, Template);
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		if(node.type != XmlNodeType.Element)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		char[] proto;
		if(!getAttr(node, "function", proto))
		{
			return new TemplateDataNode!(TemplateCtxt)(null);
		}
		
		uint i = locate(proto, '(');
		if(i == proto.length) return new TemplateDataNode!(TemplateCtxt)(null);
		char[] name = proto[0 .. i];
		++i;
		uint j = locate(proto, ')', i);
		if(j == proto.length) return new TemplateDataNode!(TemplateCtxt)(null);
		char[][] params = split(proto[i .. j], ",");
		
		auto fnTmpl = new Template;
		auto funcNode = TemplateContainerNode!(TemplateCtxt).createFromChildren(node, fnTmpl, childProcessor);
		auto fn = new SenderoTemplateFunction!(Template, TemplateCtxt)(funcNode, fnTmpl, params);
		tmpl.functionCtxt.addFunction(name, fn);
		
		return new TemplateDataNode!(TemplateCtxt)(null);
	}
}

class SenderoTemplateFunction(Template, TemplateCtxt) : IFunctionBinding
{
	this(ITemplateNode!(TemplateCtxt) funcNode, Template tmpl, char[][] paramNames)
	{
		this.funcNode = funcNode;
		this.tmpl = tmpl;
		this.paramNames = paramNames;
	}
	
	ITemplateNode!(TemplateCtxt) funcNode;
	Template tmpl;
	char[][] paramNames;
	
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		scope ctxt = new TemplateCtxt(tmpl, null);
		ctxt.execCtxt = new ExecutionContext(parentCtxt);
		for(int i = 0; i < paramNames.length && i < params.length; ++i)
		{
			ctxt.execCtxt.addVar(paramNames[i], params[i]);
		}
		
		auto res = new ArrayWriter!(char);
		funcNode.render(ctxt, cast(Consumer)&res.append);
		
		char[] str = res.get;	
		
		VariableBinding var;
		var.set(str);
		return var;
	}
}

class SenderoStaticNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	mixin NestedProcessorCtr!(TemplateCtxt, Template);
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		if(node.type != XmlNodeType.Element)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		auto x = TemplateContainerNode!(TemplateCtxt).createFromChildren(node, tmpl, childProcessor);
		auto res = new ArrayWriter!(char);
		auto ctxt = tmpl.staticCtxt;
		
		x.render(ctxt, cast(Consumer)&res.append);
		
		return new TemplateDataNode!(TemplateCtxt)(res.get);

	}
}