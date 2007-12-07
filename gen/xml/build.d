import sendero.xml.XmlTemplate;
import tango.io.File;
import tango.io.Stdout;

void main()
{
	XmlTemplateInstance templ;
	char[] src;
	templ = XmlTemplate.get("XmlParser.d.xml");
	templ["parserName"] = "XmlParser";
	src = templ.render;
	//Stdout(src);
	auto f = new File("../../sendero/xml/XmlParser.d");
	f.write(cast(void[])src);
	
	templ = XmlTemplate.get("XmlNodeParser.d.xml");
	templ["parserName"] = "XmlNodeParser";
	src = templ.render;
	Stdout(src);
}