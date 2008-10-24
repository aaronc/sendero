module sendero.util.syndication.Atom;

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
		else printer.format(`<{} type="text">`, node);
		
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
	char[] type;
	
	void print(Printer printer)
	{
		printer(`<link`);
		if(rel.length) printer.format(` rel="{}"`, rel);
		if(type.length) printer.format(` type="{}"`, type);
		printer.format(` href="{}" />`, href);
		printer.newline;
	}
}

char[] getValue(XmlDocument.Node node)
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
	char[] id;
	AtomLink[] links;
	Time updated;
	AtomAuthor[] authors;
	AtomContributor[] contributors;
	AtomCategory[] categories;
	
	protected bool handleCommonElements(XmlDocument.Node node, ref char[] value, ref char[] type)
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
			AtomLink link;
			auto href = node.getAttribute("href");
			if(href) {
				link.href = href.rawValue;
			}
			auto rel = node.getAttribute("rel");
			if(rel) {
				link.rel = rel.rawValue;
			}
			if(type) {
				link.type = type;
			}
			links ~= link;
			return true;
		case "id":
			this.id = value;
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
		printer.formatln(`<id>{}</id>`, id);
		//printer.formatln(`<link href="{}" />`, url);
		foreach(link; links) link.print(printer);
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
	
	private this(XmlDocument.Node entry)
	{
		parse_(entry);
	}
	
	private void parse_(XmlDocument.Node entry)
	{
		foreach(node; entry.children)
		{
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
	private this(XmlDocument.Node author)
	{
		parse_(author);
	}
	
	char[] personType() { return "author"; }
}

class AtomContributor : AtomPerson
{
	private this(XmlDocument.Node contributor)
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
	
	protected void parse_(XmlDocument.Node person)
	{
		foreach(node; person.children)
		{
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
	
	this(char[] term)
	{
		this.term = term;
	}
	
	private this(XmlDocument.Node category)
	{
		parse_(category);
	}
	
	private void parse_(XmlDocument.Node category)
	{
		foreach(node; category.attributes)
		{
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
	package this()
	{
		
	}
	
	this(char[] url)
	{
		this.url = url;
	}
	
	char[] subtitle;
	AtomEntry[] entries;
	
	char[] url;
	char[] src;
	
	static AtomFeed parse(char[] src)
	{
		auto f = new AtomFeed;
		f.parse_(src);
		return f;
	}
	
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
	
	void publish(void delegate(char[]) consumer, AtomPublishStyle style)
	{
		auto printer = new IndentingPrinter(consumer);
		
		printer(`<?xml version="1.0" encoding="UTF-8"?>`).newline;
		printer(`<feed xmlns="http://www.w3.org/2005/Atom">`).newline;
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
	//	return "application/atom+xml";
		return "text/xml";
	}
	
	protected void printEntries_(Printer printer, AtomPublishStyle style)
	{
		foreach(entry; entries) {
			entry.print(printer, style);
			printer.newline;
		}
	}
	
	package void parseFeed_(XmlDocument.Node feed)
	{
		foreach(node; feed.children)
		{
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
		
		auto doc = new XmlDocument;
		doc.parse(src);
		
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
