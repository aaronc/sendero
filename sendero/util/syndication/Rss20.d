module sendero.util.syndication.Rss20;

import sendero.util.syndication.Common;
import tango.net.http.HttpGet;
import tango.time.Time, tango.time.ISO8601;
import tango.text.convert.TimeStamp;

import sendero.time.Format;

import sendero_base.xml.XmlEntities;
import sendero_base.util.IndentingPrinter;

alias IndentingPrinter Printer;
alias encodeBuiltinEntities encode;

import sendero.http.IRenderable;

debug import tango.io.Stdout;

class Rss20Common
{
	char[] title;
	char[] link;
	char[] description;
	Time pubDate;
	
	protected bool handleCommonElements(XmlDocument.Node node, ref char[] value)
	{
		if(node.rawValue.length) value = node.rawValue;
		else if(node.firstChild && (
				node.firstChild.type == XmlNodeType.Data ||
				node.firstChild.type == XmlNodeType.CData)) {
			value = node.firstChild.rawValue;
		}
		
		switch(node.localName)
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
		case "pubDate":
			rfc1123(value, pubDate);
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
	}
}

class Rss20Item : Rss20Common
{
	this()
	{
		
	}
	
	char[] author;
	char[][] categories;
	
	void print(Printer printer)
	{		
		printer("<item>").newline;
		printer.indent;
			printCommonElements(printer);
			printer.formatln(`<author>{}</author>">`, author);
			foreach(cat; categories)
				printer.formatln(`<category>{}</category>`, cat);
		printer.dedent;
		printer("</item>").newline;
	}
	
	private this(XmlDocument.Node entry)
	{
		parse_(entry);
	}
	
	private void parse_(XmlDocument.Node entry)
	{
		foreach(node; entry.children)
		{
			char[] value;
			
			if(handleCommonElements(node, value))
				continue;
			
			switch(node.localName)
			{
			case "author": 
				this.author = value;
				break;
			case "category":
				this.categories ~= value;
				break;
			default:
				break;
			}
		}
	}
}

class Rss20Feed : Rss20Common, IRenderable
{
	package this()
	{
		
	}
	
	this(char[] url)
	{
		this.url = url;
	}
	
	Rss20Item[] items;
	
	char[] url;
	char[] src;
	
	void parse()
	{
		parse_(src);
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
	
	void publish(void delegate(char[]) consumer)
	{
		auto printer = new IndentingPrinter(consumer);
		
		printer(`<?xml version="1.0" encoding="UTF-8"?>`).newline;
		printer(`<rss version="2.0">`).newline; printer.indent;
		printer(`<channel>`).newline;
		printer.newline;
		printer.indent;
			printCommonElements(printer);
			printEntries_(printer);
		printer.dedent;
		printer("</channel>").newline;
		printer.dedent; printer(`</rss>`).newline;
	}
	
	void render(void delegate(void[]) write)
	{
		publish(cast(void delegate(char[]))write);
	}
	
	char[] contentType()
	{
		return "text/xml";
	}
	
	protected void printEntries_(Printer printer)
	{
		foreach(item; items) {
			item.print(printer);
			printer.newline;
		}
	}
	
	package void parseChannel_(XmlDocument.Node channel)
	{
		foreach(node; channel.children)
		{
			char[] value;
			
			if(handleCommonElements(node, value))
				continue;
			
			switch(node.localName)
			{
			case "item":
				items ~= new Rss20Item(node);
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
			if(n.name != "rss") continue;
			foreach(m; n.children) {
				if(m.name != "channel") continue;
				parseChannel_(m);
				break;
			}
			break;
		}
	}
}

debug(SenderoUnittest) {
	
	unittest
	{
	
	}
}
