module sendero.xml.XPath;

import sendero.xml.xpath10.Expression;
import sendero.xml.xpath10.Parser;
import sendero.xml.XmlNode;

import tango.io.Stdout;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

public import sendero.vm.ExecutionContext;

bool compileXPath10(char[] xpath, inout Expression expr)
{
	SyntaxTree* root;
	if ( parse("", xpath, root, true) ) {
            Expression value;
            root.Expr(expr);
			return true;
		}
		else return false;
}
	
ExecutionContext createXPathContext(XmlNode node)
{
	auto ctxt = new ExecutionContext;
	ctxt.contextNode = node;
	return ctxt;
}

Var execXPath10(char[] xpath, XmlNode node)
{
	Expression expr;
	if(!compileXPath10(xpath, expr)) return Var();
	auto ctxt = createXPathContext(node);
	return expr.exec(ctxt);
}
