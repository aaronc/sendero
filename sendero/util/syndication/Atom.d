module sendero.util.syndication.Atom;

import tango.text.xml.Document;
import tango.net.http.HttpGet;
import tango.time.Time, tango.time.ISO8601;

import sendero.time.Format;

import sendero_base.xml.XmlEntities;
import sendero_base.util.IndentingPrinter;

alias IndentingPrinter Printer;
alias encodeBuiltinEntities encode;

debug import tango.io.Stdout;

enum AtomPublishStyle { Short, Long };

class AtomCommon
{
	char[] title;
	char[] url;
	Time updated;
	AtomAuthor[] authors;
	AtomCategory[] categories;
	
	protected bool handleCommonElements(Document!(char).Node node, ref char[] value, ref char[] type)
	{
		if(node.rawValue.length) value = node.rawValue;
		else if(node.firstChild && (
				node.firstChild.type == XmlNodeType.Data ||
				node.firstChild.type == XmlNodeType.CData)) {
			value = node.firstChild.rawValue;
		}
		
		auto typeAttr = node.getAttribute("type");
		if(typeAttr) type = typeAttr.rawValue;
		if(type == "html") {
			value = decodeBuiltinEntities(value);
		}
		
		switch(node.localName)
		{
		case "title":
			this.title = value;
			return true;
		case "updated":
			parseDateAndTime(value, this.updated); 
			return true;
		case "link":
			auto href = node.getAttribute("href");
			if(href) {
				this.url = href.rawValue;
			}
			return true;
		case "category":
			categories ~= new AtomCategory(node);
			return true;
		case "author":
			authors ~= new AtomAuthor(node);
			return true;
		default:
			return false;
		}
	}
	
	protected void printCommonElements(Printer printer)
	{
		printer.formatln("<title>{}</title>", encode(title));
		printer.formatln(`<id>{}</id>">`, url);
		printer.formatln(`<link href="{}">`, url);
		printer.formatln("<updated>{}</updated>", formatRFC3339(updated));
		foreach(author; authors) author.print(printer);
		foreach(category; categories) category.print(printer);
	}
}

class AtomEntry : AtomCommon
{
	this()
	{
		
	}
	
	char[] summary;
	char[] content;
	char[] contentType, summaryType;
	
	void print(Printer printer, AtomPublishStyle style)
	{
		void printContent()
		{
			if(contentType.length) printer.formatln(`<content type="{}">`, contentType);
			else printer("<content>").newline;
			printer.indent;
			printer(encode(content)).newline;
			printer.dedent;
			printer("</content>").newline;
		}
		
		void printSummary()
		{
			if(summaryType.length) printer.formatln(`<summary type="{}">`, summaryType);
			else printer("<summary>").newline;
			printer.indent;
			printer(encode(summary)).newline;
			printer.dedent;
			printer("</summary>").newline;
		}
	
		
		printer("<entry>").newline;
		printer.indent;
			printCommonElements(printer);
			if(AtomPublishStyle.Long) {
				if(content.length) printContent;
				else if(summary.length) printSummary;
			}
			else if(summary.length) printSummary;
		printer.dedent;
		printer("</entry>").newline;
	}
	
	private this(Document!(char).Node entry)
	{
		parse_(entry);
	}
	
	private void parse_(Document!(char).Node entry)
	{
		foreach(node; entry.children)
		{
			Stdout.formatln("entry node.name: {}", node.name);
			
			char[] value, type;
			
			if(handleCommonElements(node, value, type))
				continue;
			
			switch(node.localName)
			{
			case "content": 
				this.content = value;
				this.contentType = type;
				break;
			case "summary":
				this.summary = value;
				this.summaryType = type;
				break;
			default:
				break;
			}
		}
	}
}

class AtomAuthor
{
	char[] name;
	char[] email;
	char[] uri;
	
	void print(Printer printer)
	{
	
	}
	
	private this(Document!(char).Node author)
	{
		parse_(author);
	}
	
	private void parse_(Document!(char).Node author)
	{
		foreach(node; author.children)
		{
			Stdout.formatln("author node.name: {}", node.name);
			switch(node.localName)
			{
			case "name": this.name = node.rawValue; break;
			case "uri": this.uri = node.rawValue; break;
			case "email": this.email = node.rawValue; break;
			default:
				break;
			}
		}
	}
}

class AtomCategory
{
	char[] term;
	char[] scheme;
	char[] label;
	
	void print(Printer printer)
	{
		
	}
	
	private this(Document!(char).Node category)
	{
		parse_(category);
	}
	
	private void parse_(Document!(char).Node category)
	{
		foreach(node; category.attributes)
		{
			Stdout.formatln("category attr.name: {}", node.name);
			switch(node.localName)
			{
			case "term": this.term = node.rawValue; break;
			case "scheme": this.scheme = node.rawValue; break;
			case "label": this.label = node.rawValue; break;
			default:
				break;
			}
		}
	}
}

class AtomFeed : AtomCommon
{
	private this()
	{
		
	}
	
	this(char[] url)
	{
		this.url = url;
	}
	
	char[] subtitle;
	AtomEntry[] entries;
	bool error = true;
	
	static AtomFeed parse(char[] src)
	{
		auto f = new AtomFeed;
		f.parse_(src);
		return f;
	}
	
	void get()
	{
		try
		{
			auto page = new HttpGet(url);
			auto res = cast(char[])page.read;
			parse_(res);
			error = false;
		}
		catch(Exception ex)
		{
			error = true;
		}
	}
	
	void publish(void delegate(char[]) consumer, AtomPublishStyle style)
	{
		auto printer = new IndentingPrinter(consumer);
		
		printer("<?xml version='1.0' encoding='utf-8'?>").newline;
		printer("<feed xmlns='http://www.w3.org/2005/Atom'>").newline;
		printer.newline;
		printer.indent;
			printCommonElements(printer);
			foreach(entry; entries) {
				entry.print(printer, style);
				printer.newline;
			}
		printer.dedent;
		printer("</feed>").newline;
	}
	
	private void parseFeed_(Document!(char).Node feed)
	{
		foreach(node; feed.children)
		{
			Stdout.formatln("node.name: {}", node.name);
			
			char[] value, type;
			
			if(handleCommonElements(node, value, type))
				continue;
			
			switch(node.localName)
			{
			case "entry":
				entries ~= new AtomEntry(node);
				break;
			case "subtitle": this.subtitle = value; break;
			default:
				break;
			}
		}
	}
	
	private void parse_(char[] src)
	{
		auto doc = new Document!(char);
		doc.parse(src);
		
		Stdout(src).newline;
		
		foreach(n; doc.root.children)
		{
			if(n.name == "feed")
			{
				parseFeed_(n);
			}
		}
	}
}

debug {
	
	unittest
	{
		auto f = new AtomFeed("http://projects.practivist.org/news?format=atom");
		f.get;
		f.publish((char[] val){Stdout(val);}, AtomPublishStyle.Short);
	}
}