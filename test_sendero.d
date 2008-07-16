//import sendero.view.SenderoTemplate;

import sendero.vm.Expression;
import sendero.vm.Expression2;
import sendero.vm.Object;
import sendero.vm.Array;
import sendero.view.expression.Compile;
import sendero.util.Hash;

import sendero.xml.XPath;

debug(SenderoUnittest) {

import tango.io.Stdout;
import tango.io.File;
import sendero_base.xml.XmlNode;
	
unittest
{
	void printRes(Var var)
	{
		if(var.type == VarT.Array)
		{
			foreach(node; var.arrayBinding)
			{
				assert(node.type == VarT.Node);
				Stdout(print(node.xmlNode)).newline;
			}
		}
		else if(var.type == VarT.Node)
			Stdout(print(var.xmlNode)).newline;
	}
	
	auto f = new File("hamlet.xml");
	auto txt = cast(char[])f.read;
	auto root = parseXmlTree(txt);
	auto res = execXPath10("//PERSONA", root);
//	printRes(res);
	
	auto speech1 = execXPath10("//SPEECH[1]", root);
	auto ctxt = new ExecutionContext;
	ctxt.addVar("speech1", speech1);
//	printRes(speech1);
	
	auto speechLast = execXPath10("//SPEECH[last()]", root);
	ctxt.addVar("speechLast", speechLast);
//	printRes(speechLast);
	
	/+Expression expr;
	assert(compileXPath10("$speech1/LINE", expr));
	auto res2 = expr.exec(ctxt);
//	printRes(res2);+/
	
	auto personae = execXPath10("//PERSONAE[last()][TITLE]", root);
	printRes(personae);
	
	auto root2 = parseXmlTree("<xml attr='test' attr2='test2'></xml>");
	
	personae = execXPath10("//@attr", root2);
	//assert(personae.type == VarT.Node);
	//assert(personae.xmlNode.type == XmlNodeType.Element);
	printRes(personae);
	
	/*f = new File("mscorlib.xml");
	txt = cast(char[])f.read;
	auto mscorlib = parseXmlTree(txt);
	res = execXPath10("//member/@name[position() < 10]", mscorlib);
	printRes(res);*/
	
}
}

import qcf.TestRunner;

int main(char[][] args)
{
	return 0;
}