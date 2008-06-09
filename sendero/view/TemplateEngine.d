/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.view.TemplateEngine;

public import sendero.xml.XmlNode;

debug import tango.io.Stdout;

alias void delegate(void[]) Consumer;

interface ITemplateNode(TemplateCtxt)
{
	void render(TemplateCtxt tCtxt, Consumer consumer);
}

class TemplateContainerNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	ITemplateNode!(TemplateCtxt)[] children;
	
	void render(TemplateCtxt tCtxt, Consumer consumer)
	{
		foreach(child; children)
		{
			child.render(tCtxt, consumer);
		}
	}
	
	static TemplateContainerNode!(TemplateCtxt) createFromChildren(Template)(XmlNode node, Template tmpl, INodeProcessor!(TemplateCtxt, Template) proc)
	{
		auto container = new TemplateContainerNode!(TemplateCtxt);
		foreach(child; node.children)
		{
			container.children ~= proc(child, tmpl);
		}
		return container;
	}
}


class TemplateElementNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(char[] prefix, char[] localName)
	{
		if(prefix.length)
			name = prefix ~ ":" ~ localName;
		else
			name = localName;
	}
	
	char[] name;
	
	ITemplateNode!(TemplateCtxt)[] children;
	ITemplateNode!(TemplateCtxt)[] attributes;
	
	void render(TemplateCtxt ctxt, Consumer consumer)
	{
		consumer("<" ~ name);
			
		foreach(attr; attributes)
		{
			consumer(" ");
			attr.render(ctxt, consumer);
		}
		
		if(children.length)
		{
			consumer(">");
			foreach(child; children)
			{
				child.render(ctxt, consumer);
			}
			consumer("</" ~ name ~ ">");
		}
		else
		{
			consumer(" />");
		}
	}
}

class TemplateAttributeNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(char[] prefix, char[] localName, char[] value)
	{
		if(prefix.length)
			name = prefix ~ ":" ~ localName;
		else
			name = localName;
		this.value = value;
	}
	
	char[] name;
	char[] value;
	
	void render(TemplateCtxt tCtxt, Consumer consumer)
	{
		consumer(name ~ "=" ~ "\"" ~ value ~ "\"");
	}
}

class TemplateDataNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(char[] src)
	{
		this.src = src;
	}
	
	char[] src;
	
	void render(TemplateCtxt tCtxt, Consumer consumer)
	{
		consumer(src);
	}
}

class TemplateGenericNode(TemplateCtxt) : ITemplateNode!(TemplateCtxt)
{
	this(XmlNode node)
	{
		this.node = node;
	}
	
	XmlNode node;
	
	void render(TemplateCtxt tCtxt, Consumer consumer)
	{
		consumer(print(node));
	}
}

interface INodeProcessor(TemplateCtxt, Template)
{
	ITemplateNode!(TemplateCtxt) process(XmlNode, Template);
	alias process opCall;
}

interface IAttributeProcessor(TemplateCtxt, Template)
{
	ITemplateNode!(TemplateCtxt) processAttr(XmlNode, Template);
}

template NestedProcessorCtr(TemplateCtxt, Template)
{
	this(INodeProcessor!(TemplateCtxt, Template) childProcessor)
	{
		this.childProcessor = childProcessor;
	}
	
	protected INodeProcessor!(TemplateCtxt, Template) childProcessor;
}

class DefaultElemProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	mixin NestedProcessorCtr!(TemplateCtxt, Template);
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		debug assert(node.type == XmlNodeType.Element);
		
		if(node.type != XmlNodeType.Element)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		auto elem = new TemplateElementNode!(TemplateCtxt)(node.prefix, node.localName);
		foreach(attr; node.attributes)
		{
			elem.attributes ~= processAttr(attr, tmpl);
		}
		
		foreach(child; node.children)
		{
			elem.children ~= childProcessor(child, tmpl);
		}
		
		return elem;
	}
	
	protected ITemplateNode!(TemplateCtxt) processAttr(XmlNode attr, Template tmpl)
	{
		return new TemplateAttributeNode!(TemplateCtxt)(attr.prefix, attr.localName, attr.rawValue);
	}
}

class DefaultDataProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template)
	{
		debug assert(node.type == XmlNodeType.Data);
		
		if(node.type != XmlNodeType.Data)
			return new TemplateDataNode!(TemplateCtxt)(null);
		
		return new TemplateDataNode!(TemplateCtxt)(node.rawValue);
	}
}

class DefaultNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template)
	{
		return new TemplateGenericNode!(TemplateCtxt)(node);
	}
}

class NullNodeProcessor(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{
	ITemplateNode!(TemplateCtxt) process(XmlNode, Template)
	{
		return new TemplateDataNode!(TemplateCtxt)(null);
	}
}

class DefaultTemplate(TemplateCtxt, Template, LocaleT)
{
	ITemplateNode!(TemplateCtxt) rootNode;
	
	TemplateCtxt createInstance(LocaleT locale)
	{
		return new TemplateCtxt(cast(Template)this, locale);
	}
}

class DefaultTemplateContext(TemplateCtxt, Template)
{
	this(Template tmpl)
	{
		this.tmpl = tmpl;
	}
	
	Template tmpl;
}

class TemplateCompiler(TemplateCtxt, Template) : INodeProcessor!(TemplateCtxt, Template)
{	
	this()
	{
		defaultProcessor = new DefaultNodeProcessor!(TemplateCtxt, Template);
		defaultElemProcessor = new DefaultElemProcessor!(TemplateCtxt, Template)(this);
		defaultDataProcessor= new DefaultDataProcessor!(TemplateCtxt, Template);
	}
	
	ITemplateNode!(TemplateCtxt) process(XmlNode node, Template tmpl)
	{
		switch(node.type)
		{
		case XmlNodeType.Element:	
			auto procs = node.prefix in elemProcessors;
			if(procs) {
				auto proc = node.localName in *procs;
				if(proc) return proc.process(node, tmpl);
				proc = "" in *procs;
				if(proc) return proc.process(node, tmpl);
			}
			
			
			foreach(attr; node.attributes)
			{
				auto procs = attr.prefix in attrProcessors;
				if(procs) {
					auto proc = attr.localName in *procs;
					if(proc) return proc.processAttr(attr, tmpl);
					proc = "" in *procs;
					if(proc) return proc.processAttr(attr, tmpl);					
				}
			}
			
			return defaultElemProcessor(node, tmpl);
		case XmlNodeType.Data:
			return defaultDataProcessor(node, tmpl);
		case XmlNodeType.Document:
			auto rootNode = new TemplateContainerNode!(TemplateCtxt);
			foreach(child; node.children)
			{
				rootNode.children ~= this.process(child, tmpl);
			}
			return rootNode;
		default:
			return defaultProcessor(node, tmpl);
		}
	}
	
	void compile(char[] src, inout Template tmpl)
	{
		auto tree = parseXmlTree(src);
		tmpl.rootNode = this.process(tree, tmpl);
	}
		
	INodeProcessor!(TemplateCtxt, Template) defaultProcessor;
	INodeProcessor!(TemplateCtxt, Template) defaultElemProcessor;
	INodeProcessor!(TemplateCtxt, Template) defaultDataProcessor;
	INodeProcessor!(TemplateCtxt, Template)[char[]][char[]] elemProcessors;
	
	IAttributeProcessor!(TemplateCtxt, Template)[char[]][char[]] attrProcessors;
	
	void addElementProcessor(char[] prefix, char[] localName, INodeProcessor!(TemplateCtxt, Template) proc)
	{
		elemProcessors[prefix][localName] = proc;
	}
	
	void addAttributeProcessor(char[] prefix, char[] localName, IAttributeProcessor!(TemplateCtxt, Template) proc)
	{
		attrProcessors[prefix][localName] = proc;
	}
}

bool getAttr(XmlNode node, char[] attrLocalName, inout char[] attrValue)
{
	foreach(attr; node.attributes)
	{
		if(attr.localName == attrLocalName)
		{
			attrValue = attr.rawValue;
			return true;
		}
	}
	return false;
}