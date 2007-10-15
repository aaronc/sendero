module sendero.xml.XmlTemplate;

import sendero.xml.XmlParser;
import sendero.util.ArrayWriter;
import sendero.util.collection.Stack;
import sendero.util.StringCharIterator;

import sendero.util.LocalText;
import sendero.util.ExecutionContext;

import tango.text.Util;

enum XmlTemplateNodeType { Element, ForElement, IfElement, Data, CData, Comment, PI, Doctype };
enum XmlTemplateActionType { If, For, Def, Content };

/*
 * Elements/Attributes:
 * d:if test, d:if
 * d:for each, d:for
 * 
 * TODO:
 * d:choose, d:when, d:otherwise (elem or attr)
 * d:def function, d:def
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
	VarPath[] params;
	
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

struct XmlTemplateNode
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

class XmlTemplate
{
	private XmlTemplateNode base;
	private size_t origLen;
	
	private this()
	{
		
	}
	
	static XmlTemplate compile(char[] templ)
	{
		auto itr = new XmlForwardNodeParser!(char)(templ);
		ushort depth = 0;
		XmlTemplateNode base;
		XmlTemplateNode* cur = &base;
		XmlTemplateNode* last = &base;
		auto stack = new Stack!(XmlTemplateNode*);
		
		void doElement()
		{
			XmlTemplateNode node;
			node.type = XmlNodeType.Element;
			
			void doFor(char[] params)
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
			
			//if(itr.namespace == "http://www.dsource.org/projects/sendero") //TODO add namespace awareness to parser
			if(itr.prefix == "d")
			{
				switch(itr.localName)
				{
				case "for":
					break;
				case "if":
					break;
				default:
					//TODO unrecognized action
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
						default:
							//TODO parse error
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
			
			if(depth == 0)
			{
				base = node;
			}
			else
			{
				(*cur).elem.children ~= node;
				last = &(*cur).elem.children[$ - 1];
			}
		}
		
		void doData()
		{
			XmlTemplateNode node;
			node.type = XmlNodeType.Data;
			node.text = parseMessage(itr.nodeValue);
			
			(*cur).elem.children ~= node;
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
				break;
			}
		}
		
		auto res = new XmlTemplate;
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
					
					if(node.elem.actions.length > i) {
						switch(node.elem.actions[i].action)
						{
						case XmlTemplateActionType.For:
							return doFor();
							break;
						case XmlTemplateActionType.If:
							return doIf();
						default:
							break;
						}
					}
					
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
				
				renderElement(0);
			}
			
			void doData(inout XmlTemplateNode node)
			{
				str ~= node.text.exec(ctxt);
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
				break;
			}
		}
		
		renderNode(base);
		return str.get;
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
	char[] templ = "<div><h1 d:if=\"$heading\" /><ul><li d:for=\"$x in $items\">{$x}</li></ul>"
		"<ul><li d:for=\"$n in $names\">{$n.first} {$n.last}, {$n.somenumber}, {$n.date, datetime, long}</li></ul>"
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
	
	Stdout(ctempl.render(ctxt)).newline;
	
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