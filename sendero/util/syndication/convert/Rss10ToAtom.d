module sendero.util.syndication.convert.Rss10ToAtom;

import sendero.util.syndication.Rss10;
import sendero.util.syndication.Atom;

debug import tango.io.Stdout;

AtomFeed[] convertRss10ToAtom(Rss10Feed rss10Feed)
{
	if(!rss10Feed.channels.length) return null;
	
	auto res = new AtomFeed[rss10Feed.channels.length];
	res.length = 0;
	foreach(channel; rss10Feed.channels)
	{
		debug Stdout.formatln("Converting rss channel {}", channel.title);
		auto atomFeed = new AtomFeed(channel.link);
		atomFeed.title = AtomTitle(channel.title);
		atomFeed.updated = channel.dcDate;
		channel.refreshItems;
		foreach(item; channel.items)
		{
			auto entry = new AtomEntry;
			entry.title  = AtomTitle(item.title);
			entry.url = item.link;
			if(item.dcSubject.length) {
				entry.categories ~= new AtomCategory(item.dcSubject);
			}
			entry.summary = AtomSummary(item.description);
			atomFeed.entries ~= entry;
		}
		res ~= atomFeed;
	}
	return res;
}