module sendero.util.syndication.Rss10;

import sendero.util.syndication.Common;
import tango.net.http.HttpGet;
import tango.time.Time, tango.time.ISO8601;

import sendero.time.Format;

import sendero_base.xml.XmlEntities;
import sendero_base.util.IndentingPrinter;

alias IndentingPrinter Printer;
alias encodeBuiltinEntities encode;

import sendero.http.IRenderable;

debug import tango.io.Stdout;

class Rss10Common
{
	char[] rdfAbout;
	char[] title;
	char[] link;
	char[] description;
	Time dcDate;
	
	protected bool handleCommonElements(XmlDocument.Node node, ref char[] value)
	{
		if(node.rawValue.length) value = node.rawValue;
		else if(node.firstChild && (
				node.firstChild.type == XmlNodeType.Data ||
				node.firstChild.type == XmlNodeType.CData)) {
			value = node.firstChild.rawValue;
		}

		switch(node.name)
		{
		case "title":
			this.title = value;
			return true;
		case "link":
			this.link = value;
			return true;
		case "description":
			description ~= value;
			return true;
		case "dc:date":
			parseDateAndTime(value, this.dcDate); 
			return true;
		default:
			return false;
		}
	}
	
	protected void printCommonElements(Printer printer)
	{
		printer.formatln(`<title>{}</title>">`, title);
		printer.formatln(`<link>{}</link>`, link);
		printer.formatln(`<description>{}</description>`, description);
		if(dcDate.ticks != 0) printer.formatln("<dc:date>{}</dc:date>", formatRFC3339(dcDate));
	}
}

class Rss10Channel : Rss10Common
{
	this(Rss10Feed feed)
	{
		this.feed_ = feed;
	}
	
	private char[][] itemsNames_;
	private Rss10Feed feed_;
	private Rss10Item[] items_;
	
	Rss10Item[] refreshItems()
	{
		items_ = null;
		foreach(itemName; itemsNames_)
		{
			foreach(item; feed_.items)
			{
				if(item.rdfAbout == itemName)
					items_ ~= item;
			}
		}
		return items_;
	}
	
	Rss10Item[] items()
	{
		if(!items_.length) return refreshItems;
		return items_;
	}
	
	void print(Printer printer)
	{		
		
		printer(`<channel rdf:about="{}">`, rdfAbout).newline;
		printer.indent;
			printCommonElements(printer);
			
		printer.dedent;
		printer("</channel>").newline;
	}
	
	private this(Rss10Feed feed, XmlDocument.Node channel)
	{
		this(feed);
		parse_(channel);
	}
	
	private void parse_(XmlDocument.Node channel)
	{
		auto rdfAboutAttr = channel.getAttribute("rdf:about");
		if(rdfAboutAttr) rdfAbout = rdfAboutAttr.rawValue;
		
		foreach(node; channel.children)
		{
			char[] value;
			
			if(handleCommonElements(node, value))
				continue;
			
			switch(node.name)
			{
			case "items":
				foreach(ch; node.children)
				{
					if(ch.name != "rdf:Seq") continue;
					foreach(ch2; ch.children)
					{
						if(ch2.name != "rdf:li") continue;
						auto resource = ch2.getAttribute("resource");
						if(!resource) resource = ch2.getAttribute("rdf:resource");
						if(resource) itemsNames_ ~= resource.rawValue;
					}
				}
				break;
			default:
				break;
			}
		}
	}
}

class Rss10Item : Rss10Common
{
	this()
	{
		
	}
	
	char[] dcSubject;
	
	void print(Printer printer)
	{		
		printer(`<item rdf:about="{}">`, rdfAbout).newline;
		printer.indent;
			printCommonElements(printer);
			
		printer.dedent;
		printer("</item>").newline;
	}
	
	private this(XmlDocument.Node item)
	{
		parse_(item);
	}
	
	private void parse_(XmlDocument.Node item)
	{
		auto rdfAboutAttr = item.getAttribute("about");
		if(rdfAboutAttr) rdfAbout = rdfAboutAttr.rawValue;
		
		foreach(node; item.children)
		{
			char[] value;
			
			if(handleCommonElements(node, value))
				continue;
			
			switch(node.name)
			{
			case "dc:subject": 
				this.dcSubject = value;
				break;
			default:
				break;
			}
		}
	}
}

class Rss10Feed : IRenderable
{
	Rss10Channel[] channels;
	Rss10Item[] items;
	char[] src;
	char[] url;
	
	package this()
	{
		
	}
	
	this(char[] url)
	{
		this.url = url;
	}
	
	bool get()
	{
		try
		{
			auto page = new HttpGet(url);
			auto res = cast(char[])page.read;
			parse_(res);
			return true;
		}
		catch(Exception ex)
		{
			return false;
		}
	}
	
	static Rss10Feed parse(char[] src)
	{
		auto f = new Rss10Feed;
		f.parse_(src);
		return f;
	}
	
	package void parseRDF_(XmlDocument.Node RDF)
	{
		foreach(node; RDF.children)
		{
			switch(node.name)
			{
			case "channel":
				channels ~= new Rss10Channel(this, node);
				break;
			case "item":
				items ~= new Rss10Item(node);
				break;
			default:
				break;
			}
		}
	}
	
	private void parse_(char[] src)
	{
		this.src = src;
		
		auto doc = new XmlDocument;
		doc.parse(src);
		
		foreach(n; doc.root.children)
		{
			if(n.name == "rdf:RDF")
			{
				parseRDF_(n);
			}
		}
	}
	
	void publish(void delegate(char[]) consumer)
	{
		auto printer = new IndentingPrinter(consumer);
		
		printer(`<?xml version="1.0"?>`).newline;
		printer(`<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" `
			`xmlns="http://purl.org/rss/1.0/">`).newline;
		printer.newline;
		printer.indent;
			foreach(channel; channels) {
				channel.print(printer);
				printer.newline;
			}
			foreach(item; items) {
				item.print(printer);
				printer.newline;
			}
		printer.dedent;
		printer("</rdf:RDF>").newline;
	}
	
	void render(void delegate(void[]) write)
	{
		publish(cast(void delegate(char[]))write);
	}
	
	char[] contentType()
	{
		return "application/rss+xml";
	}
}