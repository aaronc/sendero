module sendero.xml.XPath;

import sendero.xml.xpath10.Expression;
import sendero.xml.xpath10.Parser;
import sendero_base.xml.XmlNode;

import tango.io.Stdout;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

import sendero_base.Core;
import sendero_base.Set; 
import sendero.vm.InheritingObject;
import sendero.vm.Expression;
//public import sendero.vm.ExecutionContext;

bool compileXPath10(char[] xpath, inout IXPathExpression expr, XPathContext ctxt = null)
{
	SyntaxTree* root;
	if ( parse("", xpath, root, true) ) {
			if(ctxt is null)
				ctxt = new XPathContext;
            root.Expr(expr, ctxt);
			return true;
		}
		else return false;
}
	
XPathContext createXPathContext(XmlNode node)
{
	auto ctxt = new XPathContext;
	Var v; set(v, node); ctxt["@XPathCtxtNode"] = v;
	return ctxt;
}

Var execXPath10(char[] xpath, XmlNode node)
{
	IXPathExpression expr;
	if(!compileXPath10(xpath, expr)) return Var();
	auto ctxt = createXPathContext(node);
	return expr(ctxt);
}


debug(SenderoUnittest) {

	import tango.io.Stdout;
	import tango.io.File;
	import sendero_base.xml.XmlNode;
	import qcf.Regression;

	unittest
	{
		char[] printRes(Var var)
		{
			char[] res;
			if(var.type == VarT.Array)
			{
				foreach(node; var.array_)
				{
					assert(node.type == VarT.XmlNode);
					res ~= print(node.xmlNode_);
				}
			}
			else if(var.type == VarT.XmlNode)
				res = print(var.xmlNode_);
			return res;
		}
		
		auto r = new Regression("xpath");
		void regress(char[] name, char[] value) {
			r.regress(name, value);
		}
		
		auto f = new File("hamlet.xml");
		auto txt = cast(char[])f.read;
		auto root = parseXmlTree(txt);
		auto res = execXPath10("//PERSONA", root);
		regress("1.xml", printRes(res));
		
		auto speech1 = execXPath10("//SPEECH[1]", root);
		auto ctxt = new XPathContext;
		ctxt["speech1"] = speech1;
		regress("2.xml", printRes(speech1));
		
		auto speechLast = execXPath10("//SPEECH[last()]", root);
		ctxt["speechLast"] = speechLast;
		regress("3.xml", printRes(speechLast));
		
		foreach(k, v; ctxt)
			Stdout.formatln("Key:{}",k);
		
		IXPathExpression expr;
		assert(compileXPath10("$speech1/LINE", expr));
		auto res2 = expr(ctxt);
		regress("4.xml", printRes(res2));
		
		auto personae = execXPath10("//PERSONAE[last()][TITLE]", root);
		regress("5.xml", printRes(personae));
		
		auto root2 = parseXmlTree("<xml attr='test' attr2='test2'></xml>");
		
		personae = execXPath10("//@attr", root2);
		//assert(personae.type == VarT.Node);
		//assert(personae.xmlNode.type == XmlNodeType.Element);
		regress("6.xml", printRes(personae));
		
		f = new File("mscorlib.xml");
		txt = cast(char[])f.read;
		auto mscorlib = parseXmlTree(txt);
/+		res = execXPath10("//member/@name[position() < 10]", mscorlib);
		regress("7.xml", printRes(res));+/
		
	}
}