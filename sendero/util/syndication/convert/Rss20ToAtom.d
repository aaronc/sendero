module sendero.util.syndication.convert.Rss20ToAtom;

import sendero.util.syndication.Rss20;
import sendero.util.syndication.Atom;

debug import tango.io.Stdout;

AtomFeed convertRss20ToAtom(Rss20Feed rss20Feed)
{
	auto atomFeed = new AtomFeed(rss20Feed.link);
	atomFeed.title = AtomTitle(rss20Feed.title);
	atomFeed.updated = rss20Feed.pubDate;
	foreach(item; rss20Feed.items)
	{
		auto entry = new AtomEntry;
		entry.title  = AtomTitle(item.title);
		AtomLink link; link.href = item.link;
		entry.links ~= link;
		foreach(cat; item.categories)
			entry.categories ~= new AtomCategory(cat);
		entry.summary = AtomSummary(item.description);
		atomFeed.entries ~= entry;
	}
	return atomFeed;
}