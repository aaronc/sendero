/**
 * Copyright: Copyright (C) 2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 * 
 * Tools for processing Atom syndication feeds.
 * 
 */
module sendero.util.Atom;

import tango.text.xml.Document;

struct Author
{
	char[] name;
	char[] email;
	char[] url;
}

struct Link
{
	char[] href;
	char[] rel;
	char[] type;
	char[] hreflang;
	char[] title;
	char[] length;
}

class Entry
{
	char[] title;
	char[] subtitle;
	char[] content;
	Author author;
	Time published;
	Link link;
	char[] logo;
	char[] rights;
	Entry source;
}

class Feed
{
	char[] title;
	char[] link;
	char[] subtitle;
	char[] rights;
	
}

class AtomFeed : Feed
{
	
}

