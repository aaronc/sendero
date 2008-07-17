module sendero.xml.XPath;

import sendero.xml.xpath10.Expression;
import sendero.xml.xpath10.Parser;
import sendero_base.xml.XmlNode;

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
				foreach(node; var.arrayBinding)
				{
					assert(node.type == VarT.Node);
					res ~= print(node.xmlNode);
				}
			}
			else if(var.type == VarT.Node)
				res = print(var.xmlNode);
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
		auto ctxt = new ExecutionContext;
		ctxt.addVar("speech1", speech1);
		regress("2.xml", printRes(speech1));
		
		auto speechLast = execXPath10("//SPEECH[last()]", root);
		ctxt.addVar("speechLast", speechLast);
		regress("3.xml", printRes(speechLast));
		
		Expression expr;
		assert(compileXPath10("$speech1/LINE", expr));
		auto res2 = expr.exec(ctxt);
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
		res = execXPath10("//member/@name[position() < 10]", mscorlib);
		regress("7.xml", printRes(res));
		
	}
}