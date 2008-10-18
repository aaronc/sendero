module sendero.util.syndication.Atom;

import tango.text.xml.Document;
import tango.net.http.HttpGet;
import tango.time.Time, tango.time.ISO8601;

import sendero.time.Format;

import sendero_base.xml.XmlEntities;
import sendero_base.util.IndentingPrinter;

alias IndentingPrinter Printer;
alias encodeBuiltinEntities encode;

import sendero.http.IRenderable;

debug import tango.io.Stdout;

enum AtomPublishStyle { Short, Long };

struct AtomText(char[] node, bool multiline = false)
{
	char[] value;
	char[] type;
	
	bool hasContent()
	{
		return value.length ? true : false;
	}
	
	void print(Printer printer)
	{
		if(!value.length)
			return;
		
		if(type.length) printer.format(`<{} type="{}">`, node, type);
		else printer.formatln("<{}>", node);
		
		static if(multiline) printer.newline.indent;
		
			if(type == "html") printer(encode(value));
			else printer(value);
		
		static if(multiline) printer.newline.dedent;
		
		printer.formatln("</{}>", node);
	}
}

alias AtomText!("title") AtomTitle;
alias AtomText!("content", true) AtomContent;
alias AtomText!("summary", true) AtomSummary;
alias AtomText!("rights") AtomRights;

struct AtomLink
{
	char[] href;
	char[] rel;
	char[] title;
	
	void print(Printer printer)
	{
		
	}
}

char[] getValue(Document!(char).Node node)
{
	if(node.rawValue.length) return node.rawValue;
	else if(node.firstChild && (
			node.firstChild.type == XmlNodeType.Data ||
			node.firstChild.type == XmlNodeType.CData)) {
		return node.firstChild.rawValue;
	}
}

class AtomCommon
{
	AtomTitle title;
	AtomRights rights;
	char[] url;
	Time updated;
	AtomAuthor[] authors;
	AtomContributor[] contributors;
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
			this.title = AtomTitle(value, type);
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
		case "contributor":
			contributors ~= new AtomContributor(node);
			return true;
		case "rights":
			this.rights = AtomRights(value, type);
			return true;
		default:
			return false;
		}
	}
	
	protected void printCommonElements(Printer printer)
	{
		//printer.formatln("<title>{}</title>", encode(title));
		title.print(printer);
		printer.formatln(`<id>{}</id>">`, url);
		printer.formatln(`<link href="{}">`, url);
		if(updated.ticks != 0) printer.formatln("<updated>{}</updated>", formatRFC3339(updated));
		foreach(author; authors) author.print(printer);
		foreach(category; categories) category.print(printer);
		foreach(contributor; contributors) contributor.print(printer);
		rights.print(printer);
	}
}

class AtomEntry : AtomCommon
{
	this()
	{
		
	}
	
//	char[] summary;
//	char[] content;
//	char[] contentType, summaryType;
	AtomSummary summary;
	AtomContent content;
	Time published;
	
	void print(Printer printer, AtomPublishStyle style)
	{		
		printer("<entry>").newline;
		printer.indent;
			printCommonElements(printer);
			if(style == AtomPublishStyle.Long) {
				if(content.hasContent) content.print(printer);
				else if(summary.hasContent) summary.print(printer);
			}
			else if(summary.hasContent) summary.print(printer);
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
				this.content = AtomContent(value, type);
				break;
			case "summary":
				this.summary = AtomSummary(value, type);
				break;
			case "published":
				parseDateAndTime(value, this.published); 
				break;
			default:
				break;
			}
		}
	}
}

class AtomAuthor : AtomPerson
{
	private this(Document!(char).Node author)
	{
		parse_(author);
	}
	
	char[] personType() { return "author"; }
}

class AtomContributor : AtomPerson
{
	private this(Document!(char).Node contributor)
	{
		parse_(contributor);
	}
	
	char[] personType() { return "contributor"; }
}

abstract class AtomPerson
{
	char[] name;
	char[] email;
	char[] uri;
	
	abstract char[] personType();
	
	void print(Printer printer)
	{
		printer.formatln("<{}>", personType);
		printer.indent;
			if(name.length) printer.formatln(`<name>{}</name>`, name);
			if(email.length) printer.formatln(`<email>{}</email>`, email);
			if(uri.length) printer.formatln(`<uri>{}</uri>`, uri);
		printer.dedent;
		printer.formatln("</{}>", personType);
	}
	
	protected void parse_(Document!(char).Node person)
	{
		foreach(node; person.children)
		{
			Stdout.formatln("person node.name: {}", node.name);
			switch(node.localName)
			{
			case "name": this.name = getValue(node); break;
			case "uri": this.uri = getValue(node); break;
			case "email": this.email = getValue(node); break;
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
		printer("<category ");
		if(term.length) printer.format(`term="{}" `,term);
		if(scheme.length) printer.format(`scheme="{}" `,scheme);
		if(label.length) printer.format(`label="{}" `,label);
		printer("/>").newline;
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

class AtomFeed : AtomCommon, IRenderable
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
	
	char[] src;
	
	static AtomFeed parse(char[] src)
	{
		auto f = new AtomFeed;
		f.parse_(src);
		return f;
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
	
	void publish(void delegate(char[]) consumer, AtomPublishStyle style)
	{
		auto printer = new IndentingPrinter(consumer);
		
		printer("<?xml version='1.0' encoding='utf-8'?>").newline;
		printer("<feed xmlns='http://www.w3.org/2005/Atom'>").newline;
		printer.newline;
		printer.indent;
			printCommonElements(printer);
			printEntries_(printer, style);
		printer.dedent;
		printer("</feed>").newline;
	}
	
	void render(void delegate(void[]) write)
	{
		publish(cast(void delegate(char[]))write, AtomPublishStyle.Long);
	}
	
	char[] contentType()
	{
		return "application/atom+xml";
	}
	
	protected void printEntries_(Printer printer, AtomPublishStyle style)
	{
		foreach(entry; entries) {
			entry.print(printer, style);
			printer.newline;
		}
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
		this.src = src;
		
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

debug(SenderoUnittest) {
	
	unittest
	{
		auto f = new AtomFeed("http://projects.practivist.org/news?format=atom");
		
		f.get;
		f.publish((char[] val){Stdout(val);}, AtomPublishStyle.Short);
	}
}