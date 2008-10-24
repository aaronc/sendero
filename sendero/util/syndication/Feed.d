module sendero.util.syndication.Feed;

import sendero.util.syndication.Rss10;
import sendero.util.syndication.Atom;
import sendero.util.syndication.Rss20;

import sendero.util.syndication.Common;
import tango.net.http.HttpGet;

import sendero.util.syndication.convert.Rss10ToAtom;
import sendero.util.syndication.convert.Rss20ToAtom;

import tango.util.log.Log;
Logger log;
static this()
{
	log = Log.lookup("sendero.util.syndication.Feed");
}

class Feed
{
	enum Type { Null, Atom, Rss10, Rss20 };
	Type nativeType()
	{
		return type_;
	}
	
	void refreshConversions()
	{
		if(type_ == Type.Rss10) {
			if(rss10Feed_ !is null) {
				atomFeeds_ = convertRss10ToAtom(rss10Feed_);
			}
		}
		else if(type_ == Type.Rss20) {
			if(rss20Feed_ !is null) {
				atomFeeds_ = [convertRss20ToAtom(rss20Feed_)];
			}
		}
	}
	
	AtomFeed[] getAtomFeeds()
	{
		if(type_ == Type.Atom) return atomFeeds_;
		else if(type_ == Type.Rss10 || type_ == Type.Rss20) {
			if(!atomFeeds_.length) refreshConversions;
			return atomFeeds_;
		}
		else return null;
	}
	
	Rss10Feed getRss10Feed()
	{
		if(type_ == Type.Rss10)
			return rss10Feed_;
		else return null;
	}
	
	private Type type_ = Type.Null;
	private AtomFeed[] atomFeeds_;
	private Rss10Feed rss10Feed_;
	private Rss20Feed rss20Feed_;
	
	char[] src() { return src_; }
	char[] url() { return url_; }
	
	private char[] src_, url_;
	
	this(char[] url)
	{
		this.url_ = url;
	}
	
	void parse(char[] src)
	{
		this.src_ = src;
		parse_;
	}
	
	bool get()
	{
		try
		{
			auto page = new HttpGet(url_);
			auto res = cast(char[])page.read;
			src_ = res;
			parse_;
			return true;
		}
		catch(Exception ex)
		{
			log.error(ex.toString);
			return false;
		}
	}
	
	private void parse_()
	{
		auto doc = new XmlDocument;
		doc.parse(src_);
		
		foreach(node; doc.root.children)
		{
			switch(node.name)
			{
			case "feed":
				type_ = Type.Atom;
				auto atom = new AtomFeed(url_);
				atom.src = src_;
				atom.parseFeed_(node);
				atomFeeds_ = [atom];
				return;
			case "rdf:RDF":
				type_ = Type.Rss10;
				rss10Feed_ = new Rss10Feed(url_);
				rss10Feed_.src = src_;
				rss10Feed_.parseRDF_(node);
				return;
			case "rss":
				foreach(m; node.children) {
					if(m.name != "channel") continue;
					type_ = Type.Rss20;
					rss20Feed_ = new Rss20Feed(url_);
					rss20Feed_.src = src_;
					rss20Feed_.parseChannel_(m);
					break;
				} 
				return;
			default:
				break;
			}
		}
	}
}

