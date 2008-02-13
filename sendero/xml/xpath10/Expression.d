module sendero.xml.xpath10.Expression;

import sendero.vm.ExecutionContext;
import sendero.xml.XmlNode;

debug import tango.io.Stdout;

class XPathExpressionFn(bool filter = false)  : IFunctionBinding
{
	this(IStep rootStep)
	{
		this.rootStep = rootStep;
	}
	
	IStep rootStep;
	
	VariableBinding exec(VariableBinding[] params, ExecutionContext parentCtxt)
	{
		if(!rootStep) return Var();

		scope ctxt = new ExecutionContext(parentCtxt);
		static if(filter) {
			if(!params.length || params[0].type != VarT.Node) return Var();
			ctxt.contextNode = params[0].xmlNode;
		}
		else ctxt.contextNode = parentCtxt.contextNode;
		
		auto res = rootStep.exec(ctxt);
		res ~= rootStep.finish(ctxt);
		if(!res.length) return Var();
		else {
			Var var;
			if(res.length == 1)
				var.set(res[0]);
			else
				var.set(res);
			return var;
		}
		
		return Var();
	}
}

class PositionFn : IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext ctxt)
	{
		return ctxt.getVar("@XPathPos");
	}
}

class LastFn : IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext ctxt)
	{
		auto var = ctxt.getVar("@XPathLast");
		return ctxt.getVar("@XPathLast");
	}
}

class CountFn : IFunctionBinding
{
	VariableBinding exec(VariableBinding[] params, ExecutionContext ctxt)
	{
		if(!params.length || params[0].type != VarT.Array) return Var();
		long count = params[0].arrayBinding.length;
		Var var;
		var.set(count);
		return var;
	}
}

class UnionFn : IFunctionBinding
{
	this(Expression expr1, Expression expr2)
	{
		this.expr1 = expr1;
		this.expr2 = expr2;
	}
	private Expression expr1, expr2;

	VariableBinding exec(VariableBinding[] params, ExecutionContext ctxt)
	{
		auto v1 = expr1.exec(ctxt);
		auto v2 = expr2.exec(ctxt); 
		Var res;
		res.type = VarT.Array;
		res.arrayBinding = new UnionWrapper(v1, v2);
		return res;
	}
}

class UnionWrapper : IArrayBinding
{
	this(Var v1, Var v2)
	{
		this.v1 = v1;
		this.v2 = v2;
	}
	
	private Var v1, v2;
	
	int opApply (int delegate (inout VariableBinding val) dg)
	{
		int res;
		
		bool doArray(IArrayBinding array)
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
			if(!doArray(v1.arrayBinding)) return res;
		}
		else if ((res = dg(v1)) != 0) return res;
		
		if(v2.type == VarT.Array)
		{
			if(!doArray(v2.arrayBinding)) return res;
		}
		else if ((res = dg(v2)) != 0) return res;
		
		return res;
	}
	
	VariableBinding opIndex(size_t i)
	{
		if(v1.type == VarT.Array)
		{
			auto len1 = v1.arrayBinding.length;
			if(i < len1) return v1.arrayBinding[i];
			
			i -= len1;
			
			if(v2.type == VarT.Array)
			{
				if(i < v2.arrayBinding.length) return v2.arrayBinding[i];
			}
			else if(i == 0) return v2;
		}
		else
		{
			if(i == 0) return v1;
			--i;
			
			if(v2.type == VarT.Array)
			{
				if(i < v2.arrayBinding.length) return v2.arrayBinding[i];
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
			len += v1.arrayBinding.length;
		}
		else ++len;
		
		if(v2.type == VarT.Array)
		{
			len += v2.arrayBinding.length;
		}
		else ++len;
		
		return len;
	}
}

class Filter
{
	void exec(ExecutionContext ctxt)
	{
		
	}
}

class FilterPredicate : IFunctionBinding
{
	Expression filter;
	Expression predicate;
	
	VariableBinding exec(VariableBinding[] params, ExecutionContext ctxt)
	{
		auto var = filter.exec(ctxt);
		switch(var.type)
		{
		case VarT.Object:
			auto pred = predicate.exec(ctxt);
			if(pred.type == VarT.String)
				return var.objBinding[pred.string_];
			return Var();
		case VarT.Array:
			auto pred = predicate.exec(ctxt);
			switch(pred.type)
			{
			case VarT.Long:
				return var.arrayBinding[pred.long_];
			default:
				auto predTest = new PredicateTest(predicate);
				break;
			}
			break;
		case VarT.Node:
			
		default:
			return Var();
		}
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
	XmlNode[] exec(ExecutionContext ctxt);
	XmlNode[] finish(ExecutionContext ctxt);
	void setNextStep(IStep);
}

interface ITest
{
	bool test(XmlNode node, ExecutionContext ctxt, XmlNodeType axisType);
}

class PredicateTest
{
	this(Expression expr)
	{
		this.expr = expr;
	}
	
	Expression expr;
	
	bool test(ExecutionContext ctxt)
	{
		auto res = expr.exec(ctxt);
		
		switch(res.type)
		{
		case VarT.Bool:
			return res.bool_;
		case VarT.Long:
			auto pos = ctxt.getVar("@XPathPos");
			return pos == res.long_;
		case VarT.Array:
			return res.arrayBinding.length > 0;
		case VarT.Node:
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
	
	bool test(XmlNode node, ExecutionContext ctxt, XmlNodeType axisType)
	{
		if(node.type != axisType) return false;
		return node.prefix == prefix && node.localName == localName;
	}	
}

class WildcardPrefixTest : ITest
{
	this(char[] prefix) {this.prefix = prefix;}
	char[] prefix;
	bool test(XmlNode node, ExecutionContext ctxt, XmlNodeType axisType)
	{
		if(node.type != axisType) return false;
		return node.prefix == prefix;
	}	
}

class WildcardTest : ITest
{
	bool test(XmlNode node, ExecutionContext ctxt, XmlNodeType axisType)
	{
		if(node.type != axisType) return false;
		return true;
	}	
}

class NodeKindTest : ITest
{
	bool test(XmlNode node, ExecutionContext ctxt, XmlNodeType axisType)
	{
		return true;
	}
}

class TextKindTest : ITest
{
	bool test(XmlNode node, ExecutionContext ctxt, XmlNodeType axisType)
	{
		return node.type == XmlNodeType.Data;
	}
}

class PIKindTest : ITest
{
	char[] literal;
	bool test(XmlNode node, ExecutionContext ctxt, XmlNodeType axisType)
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
	bool test(XmlNode node, ExecutionContext ctxt, XmlNodeType axisType)
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
	
	private XmlNode[] testNode(bool finish = false)(ExecutionContext ctxt)
	{
		if(nextNode) {
			ctxt.contextNode = nextNode;
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
				res ~= ctxt.contextNode;
			}
			return res;
		}
		return null;
	}
	
	final XmlNode[] exec(ExecutionContext ctxt)
	{
		if(!ctxt.contextNode) return null;
		
		auto nodesetViewer = nodeSetViewerCtr(ctxt.contextNode);
		
		XmlNode[] res;
		
		ctxt.addVar("@XPathLast", false);
		foreach(n; nodesetViewer)
		{		
			static if(is(NodeSetViewer == AttributeAxisViewer))
				const XmlNodeType axisType = XmlNodeType.Attribute;
			else
				const XmlNodeType axisType = XmlNodeType.Element;
			
			if(!test || test.test(n, ctxt, axisType))
			{
				ctxt.addVar("@XPathPos", pos);
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
	
	final XmlNode[] finish(ExecutionContext ctxt)
	{
		ctxt.addVar("@XPathPos", pos);
		ctxt.addVar("@XPathLast", true);
		return testNode!(true)(ctxt);
		ctxt.addVar("@XPathLast", false);
		pos = 0;
	}
}