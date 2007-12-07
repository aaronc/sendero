module sendero.xml.XmlTemplate;

import sendero.xml.XmlParser;
import sendero.xml.XmlNodeType;
import sendero.util.ArrayWriter;
import sendero.util.collection.Stack;
import sendero.util.StringCharIterator;
import sendero.json.JsonObject;

import sendero.util.LocalText;
import sendero.util.ExecutionContext;

import tango.text.Util;
import tango.io.File;
import tango.io.FilePath;

debug import tango.io.Stdout;

enum XmlTemplateNodeType { Element, ForElement, IfElement, Data, CData, Comment, PI, Doctype };
enum XmlTemplateActionType { If, For, AssocFor, Def, List, DefObject, Include, Import, Extend, Block, Super, Attr, Attrs, Element, Choice, Let};

/*
 * Elements/Attributes:
 * d:if test, d:if
 * d:for each, d:for
 * d:list each sep
 * d:def function, d:def
 * d:def object (specifed in JSON)
 * d:choose, d:when, d:otherwise (elem or attr)
 * d:attr name value
 * d:let name value
 * 
 * xi:include href
 * 
 * d:extends href - TODO fix errors with multiple inheritance
 * d:block name, d:block - TODO fix errors with multiple inheritance
 * d:super - TODO fix errors with multiple inheritance
 *  
 * 
 * TODO:
 * d:import
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

struct ObjectDef
{
	Message expr;
	char[] name;
}

struct LetDef
{
	Expression expr;
	char[] name;
}


struct AttrDef
{
	Message name;
	Message val;
}

struct ChoiceDef
{
	Message expr;
	XmlTemplateNode[char[]] choices;
	XmlTemplateNode otherwise;
}

struct XmlTemplateAction
{
	XmlTemplateActionType action;
	union
	{
		VarPath[] params;
		Message expr;
		char[] str;
		ObjectDef obj;
		LetDef let;
		AttrDef attr;
		ChoiceDef choice;
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
		var.set(templ.render(ctxt));
		return var;
	}
}

class XmlTemplate
{
	private XmlTemplateNode base;
	private FunctionBindingContext functionCtxt;
	private size_t origLen;
	private XmlTemplateNode[char[]] blocks;
	private Message[char[]] object;
	
	private this()
	{
		functionCtxt = new FunctionBindingContext;
	}
	
	static XmlTemplate compile(char[] templ)
	{
		auto itr = new XmlParser!(char)(templ);
		bool retain = false;
		
		XmlTemplateNode base = new XmlTemplateNode;
		base.type = XmlNodeType.Element;

		bool text = false;
		auto res = new XmlTemplate;
		
		bool nextAttribute()
		{
			if(itr.next && itr.type == XmlTokenType.Attribute) return true;
			retain = true;
			return false;
		}
		
		void processNode(XmlTemplateNode elem, int limit = -1)
		{
			auto stack = new Stack!(XmlTemplateNode);
			ushort depth = itr.depth;
			XmlTemplateNode curElem = elem;
			XmlTemplateNode last = elem;
			
			void doElement()
			{
				bool func = false;
				bool extend = false;
				XmlTemplateNode node = new XmlTemplateNode;
				node.type = XmlNodeType.Element;
				
				void doFor(char[] params, char[] sep = null)
				{
					auto p = new StringCharIterator!(char)(params);
					
					XmlTemplateAction action;
					action.action = XmlTemplateActionType.For;
					
					if(p[0] != '$') return;
					++p;
					while(p[0] != ',' && p[0] != ' ') {
						++p; 
					}
					
					action.params ~= VarPath(p.randomAccessSlice(1, p.location));
					
					p.eatSpace;
					if(p[0] == ',') {
						++p;
						p.eatSpace;
						if(p[0] != '$') return;
						++p;
						auto loc = p.location;
						while(p[0] != ' ') {
							++p; 
						}
						
						action.action = XmlTemplateActionType.AssocFor;
						action.params ~= VarPath(p.randomAccessSlice(loc, p.location));
					}
					
					if(!p.forwardLocate('i')) return;
					if(p[0 .. 3] != "in ") return;
					if(!p.forwardLocate('$')) return;
					++p;
					
					auto loc = p.location;
					action.params ~= VarPath(p.randomAccessSlice(loc, p.length));
					
					if(sep) {
						debug assert(action.action != XmlTemplateActionType.AssocFor, "AssocList not implemented yet");
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
					processNode(node, depth);
				}
				
				void doObject(char[] name)
				{
					if(!(retain || itr.next)) return;
					if(itr.type != XmlTokenType.Data) {
						retain = true;
						return;
					}
					retain = false;
					
					XmlTemplateAction action;
					action.action = XmlTemplateActionType.DefObject;
					action.obj.expr = parseMessage(itr.value, res.functionCtxt);
					action.obj.name = name;
					node.elem.actions ~= action;
					
					while((retain || itr.next) && itr.depth > depth) { retain = false; }
					retain = true;
				}
				
				void doLet(char[] name, char[] val)
				{
					XmlTemplateAction action;
					action.action = XmlTemplateActionType.Let;
					action.let.name = name;
					//parseTextExpression(val, action.let.expr, res.functionCtxt);
					parseExpression(val, action.let.expr, res.functionCtxt);
					node.elem.actions ~= action;
					
					while((retain || itr.next) && itr.depth > depth) { retain = false; }
					retain = true;
				}
				
				void doExtendBlock(ushort d)
				{
					char[] name;
					while(nextAttribute)
					{
						if(itr.localName == "name")
						{
							name = itr.value;
							break;
						}
					}
					if(!name.length) return;
					
					auto block = new XmlTemplateNode;
					block.type = XmlNodeType.Element;
					
					processNode(block, d);
					
					res.blocks[name] = block;
				}
				
				void doExtend(char[] href)
				{
					XmlTemplateAction action;
					action.action = XmlTemplateActionType.Extend;
					action.expr = parseMessage(href, res.functionCtxt);
					node.elem.actions ~= action;
					
					while((retain || itr.next) && itr.depth > depth) {
						retain = false;
						if(itr.type == XmlTokenType.StartElement && itr.name == "d:block")
						{
							doExtendBlock(itr.depth);
						}
					}
					retain = true;
				}
				
				void doBlock(char[] name)
				{
					XmlTemplateAction action;
					action.action = XmlTemplateActionType.Block;
					action.str = name;
					node.elem.actions ~= action;
					res.blocks[name] = node;
				}
				
				void doSuper()
				{
					XmlTemplateAction action;
					action.action = XmlTemplateActionType.Super;
					node.elem.actions ~= action;
					
					while((retain || itr.next) && itr.depth > depth) {retain = false;}
					retain = true;
				}
				
				void doAttr(char[] name, char[] val)
				{
					XmlTemplateAction action;
					action.action = XmlTemplateActionType.Attr;
					action.attr.name = parseMessage(name, res.functionCtxt);
					action.attr.val = parseMessage(val, res.functionCtxt);
					curElem.elem.actions ~= action;
					
					while((retain || itr.next) && itr.depth > depth) {retain = false;}
					retain = true;
				}
				
				void doChoice(char[] expr)
				{
					XmlTemplateAction action;
					action.action = XmlTemplateActionType.Choice;
					action.choice.expr = parseMessage(expr, res.functionCtxt);
					while((retain || itr.next) && itr.depth > depth) {
						retain = false;
						if(itr.type == XmlNodeType.Element && itr.prefix == "d")
						{
							if(itr.localName == "when")
							{
								char[] val;
								while(nextAttribute)
								{
									if(itr.localName == "val")
									{
										val = itr.value;
										break;
									}
								}
								auto x = new XmlTemplateNode;
								x.type = XmlNodeType.Element;
								processNode(x, itr.depth);
								action.choice.choices[val] = x;
							}
							else if(itr.localName == "otherwise")
							{
								auto x = new XmlTemplateNode;
								x.type = XmlNodeType.Element;
								processNode(x, itr.depth);
								action.choice.otherwise = x;
							}
						}
					}
					retain = true;
					curElem.elem.actions ~= action;
				}
				
				//if(itr.namespace == "http://www.dsource.org/projects/sendero") //TODO add namespace awareness to parser
				if(itr.prefix == "d")
				{
					switch(itr.localName)
					{
					case "for":
					case "list":	
						char[] each, sep;
						while(nextAttribute)
						{
							if(itr.localName == "each")
							{
								each = itr.value;
							}
							
							if(itr.localName == "sep")
							{
								sep = itr.value;
							}
						}
						if(each) doFor(each, sep);
						break;
					case "if":
						char[] test;
						while(nextAttribute)
						{
							if(itr.localName == "test")
							{
								test = itr.value;
							}
						}
						if(test) doIf(test);
						break;
					case "def":
						while(nextAttribute)
						{
							if(itr.localName == "function")
							{
								return doFunction(itr.value);
								break;
							}
							if(itr.localName == "object")
							{
								doObject(itr.value);
								break;
							}
						}
						break;
					case "let":
						char[] name, val;
						while(nextAttribute)
						{
							if(itr.localName == "name")
							{
								name = itr.value;
							}
							if(itr.localName == "value")
							{
								val = itr.value;
							}
						}
						if(name.length && val.length) doLet(name, val);
						break;
					case "extends":
						char[] href;
						while(nextAttribute)
						{
							if(itr.localName == "href")
							{
								href = itr.value;
							}
						}
						if(href) doExtend(href);
						break;
					case "block":	
						char[] name;
						while(nextAttribute)
						{
							if(itr.localName == "name")
							{
								name = itr.value;
							}
						}
						if(name) doBlock(name);
						break;
					case "super":
						doSuper;
						break;
					case "attr":
						char[] name, val;
						while(nextAttribute)
						{
							if(itr.localName == "name")
							{
								name = itr.value;
							}
							if(itr.localName == "val")
							{
								val = itr.value;
							}
						}
						if(name.length && val.length) return doAttr(name, val); 
						break;
					case "choose":
						char[] val;
						while(nextAttribute)
						{
							if(itr.localName == "expr")
							{
								val = itr.value;
								break;
							}
						}
						if(val.length) doChoice(val); 
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
						while(nextAttribute)
						{
							if(itr.localName == "href")
							{
								href = itr.value;
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
					//version(CompactSyntax)
					//{
						if(!node.elem.qname.prefix.length)
						{
							auto str = node.elem.qname.localName;
							auto len = str.length;
							
							uint x = 0;
							char getToken(inout char[] token)
							{
								auto y = x;
								if(x >= len) return false;
								while(x < len && str[x] != '.'  && str[x] != '#') ++x;
								token = str[y .. x];
								if(x < len) {
									return str[x];
								}
								return '\0';
							}
							
							void addAttr(char[] name, char[] val)
							{
								Attribute attr;
								attr.qname.localName = name;
								attr.value = val;
								node.elem.attributes ~= attr;
							}
							
							char[] name;
							auto ch = getToken(name);
							if(!name.length) name = "div";
							node.elem.qname.localName = name;
							
							char[] id;
							char[][] classes;
							while(ch) {
								++x;
								char[] token;
								switch(ch)
								{
								case '.':
									ch = getToken(token);
									classes ~= token;
									break;
								case '#':
									ch = getToken(token);
									id = token;
									break;
								default:
									break;
								}
							}
							
							if(id.length) addAttr("id", id);
							if(classes.length) {
								bool first = true;
								char[] clsdef;
								foreach(cls; classes)
								{
									if(!first) clsdef ~= " ";
									clsdef ~= cls;
									first = false;
								}
								addAttr("class", clsdef);
							}
						}
					//}
					
					while(nextAttribute)
					{
						//if(itr.namespace == "http://www.dsource.org/projects/sendero") //TODO add namespace awareness to parser
						if(itr.prefix == "d")
						{
							switch(itr.localName)
							{
							case "for":
								doFor(itr.value);
								break;
							case "if":
								doIf(itr.value);
								break;
							case "def":
								return doFunction(itr.value);
								break;
							case "block":
								doBlock(itr.value);
								break;
							default:
								//TODO parse error
								break;
							}
						}
						else
						{
							auto msg = parseMessage(itr.value, res.functionCtxt);
							if(msg.params.length) {
								XmlTemplateAction action;
								action.action = XmlTemplateActionType.Attr;
								action.attr.name = parseMessage(itr.name, res.functionCtxt);
								action.attr.val = msg;
								node.elem.actions ~= action;
							}
							else {
								Attribute attr;
								attr.qname.prefix = itr.prefix;
								attr.qname.localName = itr.localName;
								attr.value = itr.value;
								node.elem.attributes ~= attr;
							}
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
					curElem.elem.children ~= node;
					last = node;
				}
			}
			
			void doData()
			{
				auto node = new XmlTemplateNode;
				char[] val = itr.value;
				auto len = val.length;
				uint i = 0;
				while(i < len && val[i] < 32) {++i;} //Check for all whitespace in data
				if(i == len) return;
				
				if(val[$ - 1] == '\n') 
					val = val[0 .. $ - 1];
				else if(val.length > 2 && val[$ - 2 .. $] == "\n\r") 
					val = val[0 .. $ - 2];
				
				node.type = XmlNodeType.Data;
				node.text = parseMessage(val, res.functionCtxt);
				
				curElem.elem.children ~= node;
				if(depth == 0) text = true;
			}
			
			void doDefault()
			{
				auto node = new XmlTemplateNode;
				switch(itr.type)
				{
				case XmlTokenType.Comment:
					node.type = XmlNodeType.Comment;
					node.node.value = itr.value;
					break;
				case XmlTokenType.Doctype:
					break;
				case XmlTokenType.Attribute:
					//debug Stdout(itr.prefix ~ ":" ~ itr.localName ~ "=" ~ itr.rawValue);
					debug assert(false, itr.prefix ~ ":" ~ itr.localName ~ "=" ~ itr.rawValue);
					break;
				default:
					assert(false, "Unhandled node type " ~ Integer.toUtf8(itr.type));
				}
				curElem.elem.children ~= node;
			}
			
			while((retain || itr.next) && itr.depth > limit)
			{
				retain = false;
				if(depth < itr.depth)
				{
					stack.push(curElem);
					curElem = last;
					depth = itr.depth;
				}
				else if(depth > itr.depth)
				{
					if(stack.empty) throw new Exception("Unexpected empty stack");
					while(depth > itr.depth) {
						curElem = stack.top;
						stack.pop;
						--depth;
					}
				}
				
				switch(itr.type)
				{
				case XmlTokenType.StartElement:
					doElement();
					break;
				case XmlTokenType.Data:
					doData();
					break;
				case XmlTokenType.EndElement:
				case XmlTokenType.EndEmptyElement:
					break;
				default:
					doDefault();
					break;
				}
			}
			retain = true;
		}
		
		processNode(base);
		
		res.base = base;
		res.origLen = templ.length;
		return res;
	}
	
	/*void staticSimplify()
	{
		auto ctxt = ExecutionContext.global;
		auto newRoot = new XmlTemplateNode;
		
		void copyNode(XmlTemplateNode newNode, XmlTemplateNode oldNode)
		{
			
		}
		
		copyNode(newRoot, base);
		base = newRoot;
	}*/

	char[] render(ExecutionContext ctxt, XmlTemplate child = null)
	{
		size_t growSize = cast(size_t)(origLen * 0.2);
		auto str = new ArrayWriter!(char)(origLen + growSize, growSize * 2);
		bool superNode = false;
		XmlTemplateNode parentBlock = null;
		
		void renderNode(inout XmlTemplateNode x)
		{
			void doElement(inout XmlTemplateNode node)
			{
				char[] name;
				if(node.elem.qname.localName.length) {
					if(node.elem.qname.prefix.length) name = node.elem.qname.prefix ~ ":" ~ node.elem.qname.localName;
					else name = node.elem.qname.localName;
				}
					
				Attribute[] computedAttributes;
				
				void renderElement(uint i = 0)
				{
					void doFor()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(a.params.length < 2) return;
						auto var = ctxt.getVar(a.params[1]);
						if(var.type != VarT.Array) return;
						
						//uint i = 0; uint n = var.arrayBinding.length;
						foreach(v; var.arrayBinding)
						{
							auto curCtxt = ctxt;
							scope localCtxt = new ExecutionContext(ctxt);
							ctxt = localCtxt;
							
							ctxt.addVar(a.params[0][0], v);
							//if(i == n) ctxt.addVar("__loopLast__", true);
							ctxt.addVar("__loopN__", i);
									
							renderElement(i + 1);
							
							ctxt = curCtxt;
							//ctxt.removeVar(a.params[0][0]);
							++i;
						}
					}
					
					void doAssocFor()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(a.params.length < 3) return;
						auto var = ctxt.getVar(a.params[2]);
						if(var.type != VarT.Object) return;
						
						uint i = 0; //uint n = var.objBinding.length;
						foreach(k, v; var.objBinding)
						{
							auto curCtxt = ctxt;
							scope localCtxt = new ExecutionContext(ctxt);
							ctxt = localCtxt;
							
							ctxt.addVar(a.params[0][0], k); 
							ctxt.addVar(a.params[1][0], v);
							//if(i == n) ctxt.addVar("__loopLast__", true);
							ctxt.addVar("__loopN__", i);
									
							renderElement(i + 1);
							
							ctxt = curCtxt;
							++i;
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
							if(var.bool_) return renderElement(i + 1);
							else return;
						case VarT.Long:
							if(var.long_) return renderElement(i + 1);
						case VarT.ULong:
							if(var.ulong_) return renderElement(i + 1);
						case VarT.Object:
							if(var.objBinding.length) return renderElement(i + 1);
							else return;
						case VarT.String:
							if(var.string_.length) return renderElement(i + 1);
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
						ctxt.runtimeImports ~= templ.templ.functionCtxt;
						if(templ) str ~= templ.render;
					}
					
					void doExtend()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(!a.expr) return;
						
						auto path = a.expr.exec(ctxt);
						auto templ = XmlTemplate.get(path);
						templ.ctxt = ctxt;
						if(templ) str ~= templ.render(this);
					}
					
					void doBlock()
					{
						if(superNode) {
							return renderElement(i + 1);
						}
						
						XmlTemplateAction a = node.elem.actions[i];
						if(!a.str) return;
						//curBlock = a.str;
						//scope(exit) curBlock = null;
						
						parentBlock = node;
						scope(exit) parentBlock = null;
						
						if(child) {
							auto pNode = (a.str in child.blocks);
							if(pNode) return renderNode(*pNode);
						}
						renderElement(i + 1);
					}
					
					void doSuper()
					{
						if(parentBlock) {
							superNode = true;
							renderNode(parentBlock);
							superNode = false;
						}
					}
					
					void doObject()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(!a.obj.expr || !a.obj.name.length) return;
						
						auto json = a.obj.expr.exec(ctxt);
						auto obj = JSON.parse(json);
						
						ctxt.addVar(a.obj.name, obj);				
					}
					
					void doLet()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(!a.let.name.length) return;
						
						auto val = a.let.expr.exec(ctxt);
						
						ctxt.addVar(a.let.name, val);		
					}
					
					void doAttr()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(!a.attr.name || !a.attr.val) return;
						Attribute attr;
						attr.value = a.attr.val.exec(ctxt);
						attr.qname.localName = a.attr.name.exec(ctxt);
						computedAttributes ~= attr;
						renderElement(i + 1);
					}
					
					void doChoice()
					{
						XmlTemplateAction a = node.elem.actions[i];
						if(!a.choice.expr) return;
						auto val = a.choice.expr.exec(ctxt);
						
						auto pNode = (val in a.choice.choices);
						if(pNode) {
							renderNode(*pNode);
						}
						else if(a.choice.otherwise) {
							renderNode(a.choice.otherwise);
						}					
					}
					
					//Do Current Action
					if(node.elem.actions.length > i) {
						switch(node.elem.actions[i].action)
						{
						case XmlTemplateActionType.For:
							return doFor();
						case XmlTemplateActionType.AssocFor:
							return doAssocFor();
						case XmlTemplateActionType.If:
							return doIf();
						case XmlTemplateActionType.List:
							return doList();
						case XmlTemplateActionType.Include:
							return doInclude();
						case XmlTemplateActionType.Extend:
							return doExtend();
						case XmlTemplateActionType.Block:
							return doBlock();
						case XmlTemplateActionType.Super:
							return doSuper();
						case XmlTemplateActionType.DefObject:
							return doObject();
						case XmlTemplateActionType.Let:
							return doLet();
						case XmlTemplateActionType.Attr:
							return doAttr();
						case XmlTemplateActionType.Choice:
							return doChoice();
						default:
							break;
						}
					}
					
					//Render Node Element & Contents
					if(name.length)
					{
						str ~= "<";
						str ~= node.elem.qname.print;
						foreach(attr; node.elem.attributes)
						{
							str ~= " " ~ attr.qname.print ~ "=\"" ~ attr.value ~ "\"";
						}
						
						foreach(attr; computedAttributes)
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
							
							str ~= "</" ~ node.elem.qname.print ~ ">\n";
						}
						else
						{
							str ~= " />\n";
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
	private this() {}
	
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
	
	private char[] render(XmlTemplate child)
	{
		return templ.render(ctxt, child);
	}
}

version(Unittest)
{
	import tango.io.Stdout;
	import sendero.data.Validation;
	import tango.util.time.StopWatch;
	import Integer = tango.text.convert.Integer;
	//import tango.text.locale.Convert, tango.text.locale.Core;
	
	static class Name
	{
		uint somenumber;
		char[] first;
		char[] last;
		DateTime date;
		
		static void defineValidation(Name n, IValidator v)
		{
			v.setRequired(&n.first, "Must input first name");
			v.setRequired(&n.last, "Must input last name");
		}
	}
	
void benchmark(XmlTemplateInstance inst)
{
	StopWatch watch;
	watch.start;
	uint n = 1000;
	for(uint i = 0; i < n; ++i)
	{
		inst.render;
	}
	float t = watch.stop;
	double rate = t/n * 1000;
	
	Stdout.formatln("XmlTemplate: {} iterations, {} seconds, {} ms/templ", n, t, rate);
}

unittest
{
	Stdout("beginning template tests").newline;
	
	char[] templ =
		"<div><p d:def=\"myfunction()\">Some text!!</p>"
		"<h1 d:if=\"$heading\">A heading</h1>"
		"<h1 d:def=\"mySecondFunction(heading)\">_{$heading}</h1>"
		"<ul><li d:for=\"$x in $items\">_{$x}</li></ul>"
		"<ul><li d:for=\"$n in $names\">_{$n.first} _{$n.last}, _{$n.somenumber}, _{$n.date|datetime, long}</li></ul>"
		"My first function call: _{myfunction()}"
		"My second function call: _{mySecondFunction(\"My Heading\")}"
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
	n = new Name;
	n.first = "Joe";
	n.last = "Schmoe";
	n.somenumber = 7654321;
	n.date = DateTime(1967, 3, 3);
	names ~= n;
	n = new Name;
	n.first = "Pete";
	n.last = "This Is Neat";
	n.somenumber = 7654321;
	n.date = DateTime(1967, 3, 3);
	names ~= n;
	
	ctxt.addVar("names", names);
	
	ctxt.addVar("myHeading", "Hello World!! again...");
	
	Stdout(ctempl.render(ctxt)).newline;
	
	char[] textTempl = "Here is a list of items: <d:list each=\"$x in $items\" sep=\", \">_{$x}</d:list>.";
	
	auto ctextTempl = XmlTemplate.compile(textTempl);
	Stdout(ctextTempl.render(ctxt)).newline;
	
	char[] nestedFuncs = "<div><d:def function=\"func()\"><d:def function=\"nestedFunc(x)\">_{$x}</d:def>_{nestedFunc('one')} _{nestedFunc('two')}</d:def>"
		"_{func()}</div>";
	
	auto cnestedFuncs = XmlTemplate.compile(nestedFuncs);
	Stdout(cnestedFuncs.render(ctxt)).newline;
	
	/*auto derived = XmlTemplate.get("derivedtemplate.xml");
	derived["name"] = "bob";
	Stdout(derived.render).newline;
	
	auto derived2 = XmlTemplate.get("derived2.xml");
	Stdout(derived2.render).newline;*/

	auto complex = XmlTemplate.get("test/complex.xml");
	complex["person"] = n;
	complex["names"] = names;
	Stdout(complex.render).newline;
	
	auto compact = XmlTemplate.get("test/compactsyntax.xml");
	Stdout(compact.render).newline;
	
	auto test = XmlTemplate.get("test/template.xml");
	Stdout(test.render).newline;
	benchmark(test);
	
	auto gen = XmlTemplate.get("gen/xml/XmlNodeParser.d.xml");
	
	StopWatch btWatch;
	
	auto bigtable = "<table>"
		"<tr d:for='$row in $table'>"
		"<td d:for='$c in $row'>_{$c}</td>"
		"</tr>"
		"</table>";
	
	
	ubyte[][] table;
	for(int i = 0; i < 1000; ++i)
	{
		ubyte[] row;
		for(int j = 1; j <= 10; ++j)
		{
			row ~= j;
		}
		table ~= row;
	}
	ctxt.addVar("table", table);
	
	btWatch.start;
	for(uint i = 0; i < 100; ++i) {
		auto bigtabletemp = XmlTemplate.compile(bigtable);
		Stdout(bigtabletemp.render(ctxt));
	}
	auto btTime = btWatch.stop;
	Stdout.formatln("btTime:{}", btTime * 10);
}
}