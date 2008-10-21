module sendero.util.syndication.Feed;

import sendero.util.syndication.Rss10;
import sendero.util.syndication.Atom;

import sendero.util.syndication.Common;
import tango.net.http.HttpGet;

import sendero.util.syndication.convert.Rss10ToAtom;

class Feed
{
	enum Type { Null, Atom, Rss10 };
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
	}
	
	AtomFeed[] getAtomFeeds()
	{
		if(type_ == Type.Atom) return atomFeeds_;
		else if(type_ == Type.Rss10) {
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
	private char[] src_, url_;
	
	this(char[] url)
	{
		this.url_ = url;
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
			default:
				break;
			}
		}
	}
}

