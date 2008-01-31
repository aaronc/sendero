module sendero.http.UrlStack;

import sendero.util.collection.Stack;

import Util = tango.text.Util;

class UrlStack : Stack!(char[])
{
	private void pushHead(char[] token)
	{
		if(head is null)
		{
			head = new Cell!(char[])(token);
			tail = head;
		}
		else
		{
			auto cell = new Cell!(char[])(token);
			head.prev = cell;
			cell.next = head;
			head = cell;
		}
		++count_;
	}
	
	void pushStack(UrlStack p)
	{
		auto x = p.head;
		while(x !is null)
		{
			this.push(x.t);
			x = x.next;
		}
	}
	
	char[] origUrl;
	
	static UrlStack parseUrl(char[] url)
	{
		uint i = 0;
		uint len = url.length;
		auto p = new UrlStack;
		p.origUrl = url;
		
		char[] cur;
		if(url[i] == '/')
			++i;
		while(i < len)
		{
			if(url[i] == '/')
			{
				if(cur.length) {
					p.pushHead(cur);
				}				
				cur = "";
			}
			else
			{
				cur ~= url[i];
			}
			++i;
		}
		if(cur.length)
			p.pushHead(cur);
		
		return p;
	}
	
	static UrlStack parseDotpath(char[] dotPath)
	{
		auto tokens = Util.split(dotPath, ".");
		auto p = new UrlStack;
		p.origUrl = dotPath;
		foreach_reverse(t; tokens)
		{
			p.push(t);
		}
		return p;
	}
	
	unittest
	{
		auto p = new UrlStack;
		assert(p.empty);
		p.push("test1");
		assert(!p.empty);
		assert(p.top == "test1");
		p.push("test2");
		assert(!p.empty);
		assert(p.top == "test2");
		p.pop;
		assert(!p.empty);
		assert(p.top == "test1");
		p.pop;
		assert(p.empty);
		assert(p.top == null);
		
		auto p2 = new UrlStack;
		p.push("t1");
		p2.push("t2");
		p2.push("t3");
		p.pushStack(p2);
		p.push("t4");
		assert(!p.empty);
		assert(p.top == "t4");
		p.pop;
		assert(!p.empty);
		assert(p.top == "t3");
		p.pop;
		assert(!p.empty);
		assert(p.top == "t2");
		p.pop;
		assert(!p.empty);
		assert(p.top == "t1");
		p.pop;
		assert(p.empty);
		assert(p.top == null);
		
		p = UrlStack.parseUrl("/home/sendero/hello");
		assert(!p.empty);
		assert(p.top == "home");
		p.pop;
		assert(!p.empty);
		assert(p.top == "sendero");
		p.pop;
		assert(!p.empty);
		assert(p.top == "hello");
		p.pop;
		assert(p.empty);
		
		p = UrlStack.parseDotpath("home.sendero.hello");
		assert(!p.empty);
		assert(p.top == "home");
		p.pop;
		assert(!p.empty);
		assert(p.top == "sendero");
		p.pop;
		assert(!p.empty);
		assert(p.top == "hello");
		p.pop;
		assert(p.empty);
	}	
}