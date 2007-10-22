module sendero.xml.XmlTemplate;

import sendero.xml.XmlParser;
import sendero.util.ArrayWriter;
import sendero.util.collection.Stack;
import sendero.util.StringCharIterator;

import sendero.util.LocalText;
import sendero.util.ExecutionContext;

import tango.text.Util;
import tango.io.File;
import tango.io.FilePath;

enum XmlTemplateNodeType { Element, ForElement, IfElement, Data, CData, Comment, PI, Doctype };
enum XmlTemplateActionType { If, For, Def, List, Include };

/*
 * Elements/Attributes:
 * d:if test, d:if
 * d:for each, d:for
 * d:list each sep
 * d:def function, d:def
 * 
 * xi:include href
 * 
 * TODO:
 * d:choose, d:when, d:otherwise (elem or attr)
 * d:plaintext or d:texttemplate or d:text (root element for text template)
 * 
 */

/*
struct XmlTemplateDataParam
{
	uint offset;
	char[] name;
}

class XmlTemplateNode
{
	XmlTemplateNodeType type;
	XmlTemplateNodeFunction func;
	char[] value;
	//XmlTemplateNode[] children;
	union
	{
		char[char[]] attributes;
		XmlTemplateDataParam[] params;
	}
}*/

// for two params

struct XmlTemplateAction
{
	XmlTemplateActionType action;
	union
	{
		VarPath[] params;
		Message expr;
	}
	
	void serialize(Ar)(Ar ar, short ver)
	{
		ar (action) (params);
	}
}

struct XmlTemplateElementNode
{
	QName qname;
	Attribute[] attributes;
	XmlTemplateAction[] actions;
	XmlTemplateNode[] children;
	
	void serialize(Ar)(Ar ar, short ver)
	{
		ar (qname) (attributes) (actions);
	}
}

/*struct XmlTemplateForNode
{
	char[] name;
	char[][char[]] attributes;
	char[] var;
	char[] list;
}

struct XmlTemplateActionElement
{
	char[] name;
	char[][char[]] attributes;
	
}*/

struct QName
{
	char[] prefix;
	char[] localName;
	
	char[] print()
	{
		if(prefix.length) {
			return prefix ~ ":" ~ localName;
		}
		return localName;
	}
	
	void serialize(Ar)(Ar ar, short ver)
	{
		ar (prefix) (localName);
	}
}

struct Attribute
{
	QName qname;
	char[] value;
	
	void serialize(Ar)(Ar ar, short ver)
	{
		ar (qname) (value);
	}
}

alias Attribute XmlTemplateGenericNode;

class XmlTemplateNode
{
	XmlNodeType type;
	
	union
	{
		XmlTemplateElementNode elem;
		IMessage text;
		XmlTemplateGenericNode node;
	}
	
	void serialize(Ar)(Ar ar, short ver)
	{
		ar (type);
		switch(type)
		{
		case XmlTemplateNodeType.Element:
			ar (elem);
			break;
		case XmlTemplateNodeType.Data:
			ar (text);
			break;
		default:
			ar (node);
			break;
		}
	}
}

class XmlTemplateFunction : IFunctionBinding
{
	XmlTemplate templ;
	char[][] paramNames;
	
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		scope ctxt = new ExecutionContext(parentCtxt);
		for(int i = 0; i < paramNames.length && i < params.length; ++i)
		{
			ctxt.addVar(paramNames[i], params[i]);
		}
		VariableBinding var;
		var.type = VarT.String;
		var.data = templ.render(ctxt);
		return var;
	}
}

class XmlTemplate
{
	private XmlTemplateNode base;
	//private ExecutionContext regionalCtxt;
	private FunctionBindingContext functionCtxt;
	private size_t origLen;
	
	private this()
	{
		functionCtxt = new FunctionBindingContext;
	}
	
	static XmlTemplate compile(char[] templ)
	{
		auto itr = new XmlForwardNodeParser!(char)(templ);
		ushort depth = 0;
		XmlTemplateNode base = new XmlTemplateNode;
		base.type = XmlNodeType.Element;
		XmlTemplateNode cur = base;
		XmlTemplateNode last = base;
		auto stack = new Stack!(XmlTemplateNode);
		bool text = false;
		auto res = new XmlTemplate;
		
		void doElement()
		{
			bool func = false;
			XmlTemplateNode node = new XmlTemplateNode;
			node.type = XmlNodeType.Element;
			
			void doFor(char[] params, char[] sep = null)
			{
				auto p = new StringCharIterator!(char)(params);
				
				XmlTemplateAction action;
				action.action = XmlTemplateActionType.For;
				
				char[] p1;
				char[] p2;
				
				if(p[0] != '$') return;
				++p;
				uint loc = p.location;
				if(!p.forwardLocate(' ')) return;
				
				action.params ~= VarPath(p.randomAccessSlice(loc, p.location));
				
				if(!p.forwardLocate('i')) return;
				if(p[0 .. 3] != "in ") return;
				if(!p.forwardLocate('$')) return;
				++p;
				
				loc = p.location;
				
				action.params ~= VarPath(p.randomAccessSlice(loc, p.length));
				if(sep) {
					action.action = XmlTemplateActionType.List;
					action.params ~= VarPath(sep);
				}
				
				node.elem.actions ~= action;
			}
			
			void doIf(char[] param)
			{
				if(param[0] != '$') return;
				XmlTemplateAction action;
				action.action = XmlTemplateActionType.If;
				action.params ~= VarPath(param[1 .. $]);
				node.elem.actions ~= action;
			}
			
			void doInclude(char[] param)
			{
				XmlTemplateAction action;
				action.action = XmlTemplateActionType.Include;
				action.expr = parseMessage(param, res.functionCtxt);
				node.elem.actions ~= action;
			}
			
			void doFunction(char[] proto)
			{
				uint i = locate(proto, '(');
				if(i == proto.length) return;
				char[] name = proto[0 .. i];
				++i;
				uint j = locate(proto, ')', i);
				if(j == proto.length) return;
				char[][] params = split(proto[i .. j], ",");
				
				auto templ = new XmlTemplate;
				templ.functionCtxt = res.functionCtxt;
				templ.base = node;
				auto fn = new XmlTemplateFunction;
				fn.templ = templ;
				fn.paramNames = params;
				res.functionCtxt.addFunction(name, fn);
				func = true;
			}
			
			//if(itr.namespace == "http://www.dsource.org/projects/sendero") //TODO add namespace awareness to parser
			if(itr.prefix == "d")
			{
				switch(itr.localName)
				{
				case "for":
				case "list":		
					char[] each, sep;
					while(itr.nextAttribute)
					{
						if(itr.localName == "each")
						{
							each = itr.nodeValue;
						}
						
						if(itr.localName == "sep")
						{
							sep = itr.nodeValue;
						}
					}
					if(each) doFor(each, sep);
					break;
				case "if":
					char[] test;
					while(itr.nextAttribute)
					{
						if(itr.localName == "test")
						{
							test = itr.nodeValue;
						}
					}
					if(test) doIf(test);
					break;
				case "def":
					char[] proto;
					while(itr.nextAttribute)
					{
						if(itr.localName == "function")
						{
							proto = itr.nodeValue;
						}
					}
					if(proto) return doFunction(proto);
					break;
				case "text":
				default:
					text = true;
					break;
					//TODO unrecognized action
				}
			}
			else if(itr.prefix == "xi")
			{
				if(itr.localName == "include")
				{
					char[] href;
					while(itr.nextAttribute)
					{
						if(itr.localName == "href")
						{
							href = itr.nodeValue;
						}
					}
					if(href) doInclude(href);
				}
				else if(itr.localName == "fallback")
				{
					//TODO
				}
			}
			else
			{
				node.elem.qname.prefix = itr.prefix;
				node.elem.qname.localName = itr.localName;
				
				while(itr.nextAttribute)
				{
					//if(itr.namespace == "http://www.dsource.org/projects/sendero") //TODO add namespace awareness to parser
					if(itr.prefix == "d")
					{
						switch(itr.localName)
						{
						case "for":
							doFor(itr.nodeValue);
							break;
						case "if":
							doIf(itr.nodeValue);
							break;
						case "def":
							doFunction(itr.nodeValue);
							break;
						default:
							//TODO parse error
							break;
						}
					}
					else
					{
						Attribute attr;
						attr.qname.prefix = itr.prefix;
						attr.qname.localName = itr.localName;
						attr.value = itr.nodeValue;
						node.elem.attributes ~= attr;
					}
				}
			}
			
			if(func) {
				last = node;
			}
			else if(depth == 0 && !text)
			{
				base = node;
				last = node;
			}
			else
			{
				cur.elem.children ~= node;
				last = node;
			}
		}
		
		void doData()
		{
			auto node = new XmlTemplateNode;
			node.type = XmlNodeType.Data;
			node.text = parseMessage(itr.nodeValue, res.functionCtxt);
			
			cur.elem.children ~= node;
			if(depth == 0) text = true;
		}
		
		void doDefault()
		{
			auto node = new XmlTemplateNode;
			switch(itr.type)
			{
			case XmlNodeType.Comment:
				node.type = XmlNodeType.Comment;
				node.node.value = itr.nodeValue;
				break;
			default:
				assert(false, "Unhandled node type");
			}
			cur.elem.children ~= node;
		}
		
		while(itr.nextNode)
		{
			if(depth < itr.depth)
			{
				stack.push(cur);
				cur = last;
				depth = itr.depth;
			}
			else if(depth > itr.depth)
			{
				if(stack.empty) throw new Exception("Unexpected empty stack");
				cur = stack.top;
				stack.pop;
				depth = itr.depth;
			}
			
			switch(itr.type)
			{
			case XmlNodeType.Element:
				doElement();
				break;
			case XmlNodeType.Data:
				doData();
				break;
			default:
				doDefault();
				break;
			}
		}
		
		res.base = base;
		res.origLen = templ.length;
		return res;
	}

	char[] render(ExecutionContext ctxt)
	{
		size_t growSize = cast(size_t)(origLen * 0.2);
		auto str = new ArrayWriter!(char)(origLen + growSize, growSize * 2);
		
		void renderNode(inout XmlTemplateNode x)
		{			
			void doElement(inout XmlTemplateNode node)
			{
				void renderElement(uint i = 0)
				{
					void doFor()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(a.params.length < 2) return;
						auto var = ctxt.getVar(a.params[1]);
						if(var.type != VarT.Array) return;
						
						foreach(v; var.arrayBinding)
						{
							ctxt.addVar(a.params[0][0], v); 
									
							renderElement(i + 1);
							
							ctxt.removeVar(a.params[0][0]);
						}
					}
					
					void doList()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(a.params.length < 3) return;
						auto var = ctxt.getVar(a.params[1]);
						if(var.type != VarT.Array) return;
						
						bool first = true;
						foreach(v; var.arrayBinding)
						{
							ctxt.addVar(a.params[0][0], v); 
									
							if(!first) {
								str ~= a.params[2][0]; 
							}
							renderElement(i + 1);
							
							ctxt.removeVar(a.params[0][0]);
							first = false;
						}
					}
					
					void doIf()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(a.params.length < 1) return;
						auto var = ctxt.getVar(a.params[0]);
						switch(var.type) {
						case VarT.Null:
							return;
						case VarT.Bool:
							bool b = var.data.get!(bool);
							if(b) return renderElement(i + 1);
							else return;
						case VarT.String:
							char[] str = var.data.get!(char[]);
							if(str.length) return renderElement(i + 1);
							else return;
						case VarT.Array:
							if(var.arrayBinding.length) return renderElement(i + 1);
							else return;
						default:
							return renderElement(i + 1);	
						}
					}
					
					void doInclude()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(!a.expr) return;
						auto path = a.expr.exec(ctxt);
						auto templ = XmlTemplate.get(path);
						templ.ctxt = ctxt;
						if(templ) str ~= templ.render;
					}
					
					//Do Current Action
					if(node.elem.actions.length > i) {
						switch(node.elem.actions[i].action)
						{
						case XmlTemplateActionType.For:
							return doFor();
						case XmlTemplateActionType.If:
							return doIf();
						case XmlTemplateActionType.List:
							return doList();
						case XmlTemplateActionType.Include:
							return doInclude();
						default:
							break;
						}
					}
					
					//Render Node Element & Contents
					if(node.elem.qname.localName.length)
					{
						str ~= "<";
						str ~= node.elem.qname.print;
						foreach(attr; node.elem.attributes)
						{
							str ~= " " ~ attr.qname.print ~ "=\"" ~ attr.value ~ "\"";
						}
						
						
						if(node.elem.children.length)
						{
							str ~= ">";
							
							foreach(n; node.elem.children)
							{
								renderNode(n);
							}				
							
							str ~= "</" ~ node.elem.qname.print ~ ">";
						}
						else
						{
							str ~= " />";
						}
					}
					else //Render Empty (Text) Element Node
					{
						foreach(n; node.elem.children)
						{
							renderNode(n);
						}
					}
				}
				
				renderElement(0);
			}
			
			void doData(inout XmlTemplateNode node)
			{
				str ~= node.text.exec(ctxt);
			}
			
			void doDefault(inout XmlTemplateNode node)
			{
				switch(x.type)
				{
				case XmlNodeType.Comment:
					str ~= "<!--" ~ x.node.value ~ "-->";
				default:
					break;
				}
			}
			
			switch(x.type)
			{
			case XmlNodeType.Element:
				doElement(x);
				break;
			case XmlNodeType.Data:
				doData(x);
				break;
			default:
				doDefault(x);
				break;
			}
		}
		
		renderNode(base);
		return str.get;
	}
	
	private static struct XmlTemplateCache
	{
		XmlTemplate templ;
		FilePath path;
		Time lastModified;
	}
	
	private static XmlTemplateCache[char[]] cache;
	static XmlTemplateInstance get(char[] path)
	{
		auto pt = (path in cache);
		if(!pt) {
			auto fp = new FilePath(path);
			scope f = new File(fp);
			if(!f) throw new Exception("Template not found");
			auto txt = cast(char[])f.read;
			auto templ = XmlTemplate.compile(txt);
			
			XmlTemplateCache templCache;
			templCache.templ = templ;
			templCache.path = fp;
			templCache.lastModified = fp.modified;		
			cache[path] = templCache;
			
			return new XmlTemplateInstance(templ);
		}
		
		with(*pt) {
			if(lastModified != path.modified) {
				scope f = new File(path);
				auto txt = cast(char[])f.read;
				templ = XmlTemplate.compile(txt);
				lastModified = path.modified;
			}
			return new XmlTemplateInstance(templ);
		}
	}
}

class XmlTemplateInstance
{
	private this(XmlTemplate t)
	{
		templ = t;
		ctxt = new ExecutionContext;
	}
	
	private XmlTemplate templ;
	private ExecutionContext ctxt;
	
	void opIndexAssign(T)(T t, char[] name)
	{
		ctxt.addVar(name, t);
	}
	
	void use(T)(T t)
	{
		ctxt.addVarAsRoot(t);
	}
	
	char[] render()
	{
		return templ.render(ctxt);
	}
}

version(Unittest)
{
	import tango.io.Stdout;
	//import tango.text.locale.Convert, tango.text.locale.Core;
	
	static class Name
	{
		uint somenumber;
		char[] first;
		char[] last;
		DateTime date;
	}
}

unittest
{
	char[] templ =
		"<div><p d:def=\"myfunction()\">Some text!!</p>"
		"<h1 d:if=\"$heading\">A heading</h1>"
		"<h1 d:def=\"mySecondFunction(heading)\">_{$heading}</h1>"
		"<ul><li d:for=\"$x in $items\">_{$x}</li></ul>"
		"<ul><li d:for=\"$n in $names\">_{$n.first} _{$n.last}, _{$n.somenumber}, _{$n.date: datetime, long}</li></ul>"
		"My first function call: _{myfunction()}"
		"My second function call: _{mySecondFunction(My Heading)}"
		"My third function call: _{mySecondFunction($myHeading)}"
		"</div>";
	
	auto ctempl = XmlTemplate.compile(templ);
	
	auto ctxt = new ExecutionContext;
	//ctxt.locale = ULocale.Italian;
	
	char[][] items;
	items ~= "hello";
	items ~= "world";
	ctxt.addVar("items", items);
	
	bool heading = false;
	ctxt.addVar("heading", heading);
	
	Name[] names;
	auto n = new Name;
	n.first = "John";
	n.last = "Doe";
	n.somenumber = 1234567;
	n.date = DateTime(1976, 3, 17);
	names ~= n;
	n = new Name;
	n.first = "Jackie";
	n.last = "Smith";
	n.somenumber = 7654321;
	n.date = DateTime(1942, 10, 14);
	names ~= n;
	
	ctxt.addVar("names", names);
	
	ctxt.addVar("myHeading", "Hello World!! again...");
	
	Stdout(ctempl.render(ctxt)).newline;

	char[] textTempl = "Here is a list of items: <d:list each=\"$x in $items\" sep=\", \">_{$x}</d:list>.";
	
	auto ctextTempl = XmlTemplate.compile(textTempl);
	Stdout(ctextTempl.render(ctxt)).newline;
	
	char[] nestedFuncs = "<div><d:def function=\"func()\"><d:def function=\"nestedFunc(x)\">_{$x}</d:def>_{nestedFunc(one)} _{nestedFunc(two)}</d:def>"
		"_{func()}</div>"; //Doesn't work yet!!
	
	auto cnestedFuncs = XmlTemplate.compile(nestedFuncs);
	Stdout(cnestedFuncs.render(ctxt)).newline;
	
	/*DateTime now = DateTime.now;
	char[] res;
	res.length = 100;
	Stdout(formatDateTime(res, now, "D",Culture.getCulture("es-ES"))).newline;
	auto culture = Culture.getCulture("es-ES");
	Stdout(formatDateTime(res, now, "EEEE d 'de' MMMM 'de' yyyy",culture)).newline;
	Stdout(formatDateTime(res, now, "d 'de' MMMM 'de' yyyy",culture)).newline;
	Stdout(formatDateTime(res, now, "dd/MM/yyyy",culture)).newline;
	Stdout(formatDateTime(res, now, "hh:mm:ss a v",culture)).newline;
	Stdout(formatDateTime(res, now, "yyQQQQ",culture)).newline;
	Stdout(formatDateTime(res, now, "HH:mm:ss z",culture)).newline;	
	Stdout(formatDateTime(res, now, "hh 'o''clock' a, zzzz",culture)).newline;*/	
}