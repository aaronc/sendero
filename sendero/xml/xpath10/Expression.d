/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.xml.xpath10.Expression;

//import sendero.vm.ExecutionContext;
import sendero_base.Core;
import sendero_base.Set;
import sendero.vm.Object;
import sendero.vm.Array;
import sendero.vm.InheritingObject;
import sendero.vm.Expression;
import sendero.view.ExecContext;
import sendero_base.xml.XmlNode;

debug import tango.io.Stdout;

alias ExecContext XPathContext;
alias IExpression!(ExecContext) IXPathExpression;

debug(SenderoViewDebug) debug = SenderoXPathDebug;
debug(SenderoXPathDebug) debug = SenderoVMDebug;

class XPathExpr(bool filter = false) : IExpression!(XPathContext)
{
	static if(filter)
	{
		this(IStep rootStep, IExpression!(XPathContext) filterExpr)
		{
			this.rootStep = rootStep;
			this.filterExpr = filterExpr;
		}
		IExpression!(XPathContext) filterExpr;
	}
	else
	{
		this(IStep rootStep)
		{
			this.rootStep = rootStep;
		}
	}
	
	IStep rootStep;
	
	Var opCall(XPathContext parentCtxt)
	{
		if(!rootStep) return Var();

		scope ctxt = new XPathContext(parentCtxt);
		static if(filter) {
			/+if(!params.length || params[0].type != VarT.XmlNode) {
				debug Stdout.formatln("Can't find context node");
				return Var();
			}+/
			auto ctxtNode = filterExpr(parentCtxt);
			if(ctxtNode.type != VarT.XmlNode && ctxtNode.type != VarT.Array) {
				debug Stdout.formatln("Can't find context node, instead got type: {}", ctxtNode.type);
				return Var();
			}
			ctxt["@XPathCtxtNode"] = ctxtNode;
		}
		else {
			//ctxt["@XPathCtxtNode"] = parentCtxt.contextNode;
			ctxt["@XPathCtxtNode"] = parentCtxt["@XPathCtxtNode"];
		}
		
		auto res = rootStep.exec(ctxt);
		res ~= rootStep.finish(ctxt);
		if(!res.length) return Var();
		else {
			Var var;
			if(res.length == 1)
				set(var, res[0]);
			else
				set(var, new XmlNodeSet(res));
			return var;
		}
		
		return Var();
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class XmlNodeSet : IArray
{
	this(XmlNode[] nodes)
	{
		this.nodes = nodes;
	}
	
	XmlNode[] nodes;
	
	int opApply (int delegate (inout Var val) dg)
	{		
		int res;
		foreach(ref XmlNode node; nodes)
		{
			Var v;
			v.type = VarT.XmlNode;
			v.xmlNode_ = node;
			if((res = dg(v)) != 0) break;
		}
		return res;
	}
	
	Var opIndex(size_t i)
	{
		if(i > nodes.length)
			return Var();
		
		Var res;
		res.type = VarT.XmlNode;
		res.xmlNode_ = nodes[i];
		return res;
	}
	
	size_t length()
	{
		return nodes.length;
	}
	
	void opCatAssign(Var v)
	{
		if(v.type == VarT.XmlNode)
			nodes ~= v.xmlNode_;
	}
}

class PositionExpr : IExpression!(XPathContext)
{
	Var opCall(XPathContext ctxt)
	{
		return ctxt["@XPathPos"];
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class LastExpr : IExpression!(XPathContext)
{
	Var opCall(XPathContext ctxt)
	{
		//auto var = ctxt["@XPathLast"];
		return ctxt["@XPathLast"];
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class CountFn
{
	Var exec(Var[] params, IObject ctxt)
	{
		if(!params.length || params[0].type != VarT.Array) return Var();
		long count = params[0].array_.length;
		Var var;
		set(var, count);
		return var;
	}
}

class UnionExpr : IExpression!(XPathContext)
{
	this(IExpression!(XPathContext) expr1, IExpression!(XPathContext) expr2)
	{	
		this.expr1 = expr1;
		this.expr2 = expr2;
	}
	private IExpression!(XPathContext) expr1, expr2;

	Var opCall(XPathContext ctxt)
	{
		auto v1 = expr1(ctxt);
		auto v2 = expr2(ctxt); 
		Var res;
		res.type = VarT.Array;
		res.array_ = new UnionWrapper(v1, v2);
		return res;
	}
	
	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

class UnionWrapper : IArray
{
	this(Var v1, Var v2)
	{
		this.v1 = v1;
		this.v2 = v2;
	}
	
	void opCatAssign(Var v)
	{
		
	}
	
	private Var v1, v2;
	
	int opApply (int delegate (inout Var val) dg)
	{
		int res;
		
		bool doArray(IArray array)
		{
			foreach(x; array)
			{
				if ((res = dg(x)) != 0)
		            return false;
			}
			return true;
		}
		
		if(v1.type == VarT.Array)
		{
			if(!doArray(v1.array_)) return res;
		}
		else if ((res = dg(v1)) != 0) return res;
		
		if(v2.type == VarT.Array)
		{
			if(!doArray(v2.array_)) return res;
		}
		else if ((res = dg(v2)) != 0) return res;
		
		return res;
	}
	
	Var opIndex(size_t i)
	{
		if(v1.type == VarT.Array)
		{
			auto len1 = v1.array_.length;
			if(i < len1) return v1.array_[i];
			
			i -= len1;
			
			if(v2.type == VarT.Array)
			{
				if(i < v2.array_.length) return v2.array_[i];
			}
			else if(i == 0) return v2;
		}
		else
		{
			if(i == 0) return v1;
			--i;
			
			if(v2.type == VarT.Array)
			{
				if(i < v2.array_.length) return v2.array_[i];
			}
			else if(i == 0) return v2;
		}
		return Var();
	}
	
	size_t length()
	{
		size_t len = 0;
		if(v1.type == VarT.Array)
		{
			len += v1.array_.length;
		}
		else ++len;
		
		if(v2.type == VarT.Array)
		{
			len += v2.array_.length;
		}
		else ++len;
		
		return len;
	}
}

class Filter
{
	void exec(IObject ctxt)
	{
		assert(false, "TODO not implemented");
	}
}

class FilterPredicate : IExpression!(XPathContext)
{
	IExpression!(XPathContext) filter;
	IExpression!(XPathContext) predicate;
	
	Var opCall(XPathContext ctxt)
	{
		auto var = filter(ctxt);
		switch(var.type)
		{
		case VarT.Object:
			auto pred = predicate(ctxt);
			if(pred.type == VarT.String)
				return var.obj_[pred.string_];
			return Var();
		case VarT.Array:
			auto pred = predicate(ctxt);
			switch(pred.type)
			{
			case VarT.Number:
				return var.array_[cast(size_t)pred.number_];
			default:
				auto predTest = new PredicateTest(predicate);
				break;
			}
			break;
		case VarT.XmlNode:
			assert(false, "TODO not implemented");
		default:
			return Var();
		}
	}

	debug(SenderoVMDebug) char[] toString()
	{
		return typeof(this).stringof;
	}
}

enum Axis {
	ancestor = 0,	
	ancestor_or_self = 1,	
	attribute = 2,
	child = 3,
	descendant = 4,	
	descendant_or_self = 5,	
	following,	
	following_sibling,	
	namespace,	
	parent,	
	preceding,	
	preceding_sibling,	
	self,
}

interface IStep
{
	XmlNode[] exec(XPathContext ctxt);
	XmlNode[] finish(XPathContext ctxt);
	void setNextStep(IStep);
}

interface ITest
{
	bool test(XmlNode node, XPathContext ctxt, XmlNodeType axisType);
}

class PredicateTest
{
	this(IExpression!(XPathContext) expr)
	{
		this.expr = expr;
	}
	
	IExpression!(XPathContext) expr;
	
	bool test(XPathContext ctxt)
	{
		auto res = expr(ctxt);
		
		switch(res.type)
		{
		case VarT.Bool:
			return res.bool_;
		case VarT.Number:
			auto pos = ctxt["@XPathPos"];
			if(pos.type != VarT.Number) {
				return false;
			}
			size_t rn = cast(size_t)res.number_;
			size_t pn = cast(size_t)pos.number_;
			return rn == pn ? true : false;
		case VarT.Array:
			return res.array_.length > 0;
		case VarT.XmlNode:
			return true;
		default:
			return false;
		}
	}
}

class QNameTest : ITest
{
	this(char[] prefix, char[] localName)
	{
		this.prefix = prefix;
		this.localName = localName;
	}
	
	char[] prefix;
	char[] localName;
	
	bool test(XmlNode node, XPathContext ctxt, XmlNodeType axisType)
	{
		if(node.type != axisType) return false;
		return node.prefix == prefix && node.localName == localName;
	}	
}

class WildcardPrefixTest : ITest
{
	this(char[] prefix) {this.prefix = prefix;}
	char[] prefix;
	bool test(XmlNode node, XPathContext ctxt, XmlNodeType axisType)
	{
		if(node.type != axisType) return false;
		return node.prefix == prefix;
	}	
}

class WildcardTest : ITest
{
	bool test(XmlNode node, XPathContext ctxt, XmlNodeType axisType)
	{
		if(node.type != axisType) return false;
		return true;
	}	
}

class NodeKindTest : ITest
{
	bool test(XmlNode node, XPathContext ctxt, XmlNodeType axisType)
	{
		return true;
	}
}

class TextKindTest : ITest
{
	bool test(XmlNode node, XPathContext ctxt, XmlNodeType axisType)
	{
		return node.type == XmlNodeType.Data;
	}
}

class PIKindTest : ITest
{
	char[] literal;
	bool test(XmlNode node, XPathContext ctxt, XmlNodeType axisType)
	{
		if(node.type != XmlNodeType.PI) return false;
		if(literal.length) {
			auto val = node.rawValue;
			if(val.length >= literal.length && val[0..literal.length] == literal) return true;
			return false;
		}
		return true;
	}
}

class CommentKindTest : ITest
{
	bool test(XmlNode node, XPathContext ctxt, XmlNodeType axisType)
	{
		return node.type == XmlNodeType.Comment;
	}
}

INodeSetViewer constructNodeSetViewer(NodeSetViewer)(XmlNode node)
{
	return new NodeSetViewer(node);
}

alias INodeSetViewer function(XmlNode) NodeSetViewerConstructor;

class XPathStep : IStep
{	
	this(NodeSetViewerConstructor ctr)
	{
		this.nodeSetViewerCtr = ctr;
	}
	
	this(NodeSetViewerConstructor ctr, ITest test, PredicateTest[] predicates)
	{
		this.nodeSetViewerCtr = ctr;
		this.test = test;
		this.predicates = predicates;
	}
	
	NodeSetViewerConstructor nodeSetViewerCtr;
	IStep nextStep;
	ITest test;
	PredicateTest[] predicates;
	
	long pos = 0;
	XmlNode nextNode = null;
	
	void setNextStep(IStep step)
	{
		nextStep = step;
	}
	
	private XmlNode[] testNode(bool finish = false)(XPathContext ctxt)
	{
		Var v;
		if(nextNode) {
			set(v, nextNode);
			ctxt["@XPathCtxtNode"] = v;
			nextNode = null;
			
			foreach(p; predicates)
			{
				if(!p.test(ctxt)) return null;
			}
			
			XmlNode[] res = null;
			if(nextStep) {
				res ~= nextStep.exec(ctxt);
				static if(finish)
					res ~= nextStep.finish(ctxt);
			}
			else {
				v = ctxt["@XPathCtxtNode"];
				if(v.type == VarT.XmlNode) {
					res ~= v.xmlNode_;
				}
			}
			return res;
		}
		return null;
	}
	
	final XmlNode[] exec(XPathContext ctxt)
	{
		Var v = ctxt["@XPathCtxtNode"];
		if(v.type != VarT.XmlNode && v.type != VarT.Array) {
			debug Stdout.formatln("@XPathCtxtNode not found");
			return null;
		}
		
		if(v.type == VarT.Array) {
			debug Stdout.formatln("Doing operations on a node set @XPathCtxtNode");
			auto nodeSet = v.array_;
			XmlNode[] res;
			foreach(n; nodeSet) {
				ctxt["@XPathCtxtNode"] = n;
				res ~= exec(ctxt);
			}
			ctxt["@XPathCtxtNode"] = v;
		}
		
		auto ctxtNode = v.xmlNode_;
		
		auto nodesetViewer = nodeSetViewerCtr(ctxtNode);
		
		XmlNode[] res;
		
		set(v, false);
		ctxt["@XPathLast"] =  v;
		foreach(n; nodesetViewer)
		{		
			static if(is(NodeSetViewer == AttributeAxisViewer))
				const XmlNodeType axisType = XmlNodeType.Attribute;
			else
				const XmlNodeType axisType = XmlNodeType.Element;
			
			if(!test || test.test(n, ctxt, axisType))
			{
				set(v, pos);
				ctxt["@XPathPos"] =  v;
				res ~= testNode(ctxt);
				nextNode = n;
				++pos;
			}
			else {
				continue;
			}
		}
		if(nextStep) res ~= nextStep.finish(ctxt);
		
		return res;
	}
	
	final XmlNode[] finish(XPathContext ctxt)
	{
		Var v;
		set(v, pos); ctxt["@XPathPos"] =  v;
		set(v, true); ctxt["@XPathLast"] =  v;
		auto res = testNode!(true)(ctxt);
		set(v, false); ctxt["@XPathLast"] =  v;
		pos = 0;
		return res;
	}
}