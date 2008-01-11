import sendero.xml.XmlParser;
import tango.io.Stdout;
import tango.io.File;
import tango.util.log.Log;
import tango.util.log.ConsoleAppender;

void main(char[][] args)
{
	if(args.length < 2) return;
	auto f = new File(args[1]);
	auto txt = cast(char[])f.read;	
	auto itr = new XmlParser!(char)(txt);
	auto log = Log.getLogger("TestParser");
	Log.getRootLogger.addAppender(new ConsoleAppender);
	
	log.info("Beginning Parse");
	Stdout("<html><body><table width='100%'>");
	Stdout("<tr align='left'><th>Prefix</th><th>LocalName</th><th>RawValue</th><th>Type</th><th>Depth</th></tr>");
	while(itr.next) {
		char[] type;
		with(XmlTokenType)
		{
		switch(itr.type)
		{
			case StartElement: type="StartElement"; break;
			case Attribute: type="Attribute"; break;
			case EndElement: type="EndElement"; break;
			case EndEmptyElement: type="EndEmptyElement"; break;
			case Data: type="Data"; break;
			case Comment: type="Comment"; break;
			case CData: type="CData"; break;
			case Doctype: type="Doctype"; break;
			case PI: type="PI"; break;
			case None: type="None"; break;
			default: assert(false);
		}
		}
		Stdout.formatln("<tr><td>{}</td><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr>", itr.prefix, itr.localName, itr.rawValue, type, itr.depth);
	}
	Stdout("</table></body></html>");
	
}