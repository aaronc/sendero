/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.collection.NestedMap;

import sendero.core.Memory;
import sendero.util.collection.SimpleList;
import tango.stdc.string;

debug import tango.util.Convert;

int strcmp(char[] x, char[] y)
{
	uint min = x.length;
	if(min > y.length) min = y.length;
	for(uint i = 0; i < min; ++i)
	{
		auto val = x[i] - y[i];
		if(val) return val;
	}
	if(x.length == y.length) return 0;
	if(x.length < y.length) return -1;
	else return 1;
}

struct NestedMap(T, Alloc = DefaultAllocator)
{
	struct Node
	{
		char[] key;
		NestedMap!(T, Alloc) map;
		private Node* next;
	}
	
	struct ForwardIterator
	{
		private Node* cur;
		Node* opCall() { return cur; }
		void opPostInc()
		{
			cur = cur.next;
		}
	}
	
	SimpleList!(T, Alloc) list;
	Node* first;
	
	void add(T t)
	{
		list.add(t);
	}
	
	Node* find(char[] key)
	{

		Node* node = first;
		while(node) {
			auto res = strcmp(key, node.key);
			if(res == 0) return node;
			if(res > 0) return null;
		}
		return null;
	}
	
	Node* getNode(char[] key)
	{
		Node* node = first;
		Node* last = null;
		while(node) {
			auto res = strcmp(key, node.key);
			if(res == 0) {
				return node;
			}
			else if(res < 0) {
				if(last) {
					auto temp = node;
					node =  cast(Node*)Alloc.allocate(Node.sizeof);
					memset(node, 0, Node.sizeof);
					node.next = temp;
					node.key = key;
					last.next = node;
					return node;
				}
				else {
					debug assert(node == first);
					auto temp = first;
					first =  cast(Node*)Alloc.allocate(Node.sizeof);
					memset(first, 0, Node.sizeof);
					first.next = temp;
					first.key = key;
					return first;
				}
			}
			last = node;
			node = node.next;
		}
		if(last) {
			node = cast(Node*)Alloc.allocate(Node.sizeof);
			memset(node, 0, Node.sizeof);
			node.next = null;
			node.key = key;
			last.next = node;
			return node;
		}
		else {
			first = cast(Node*)Alloc.allocate(Node.sizeof);
			memset(first, 0, Node.sizeof);
			first.next = null;
			first.key = key;
			return first;
		}
	}
	
	void add(char[] key, T t)
	{
/+		Node* node = first;
		Node* last = null;
		while(node) {
			auto res = strcmp(key, node.key);
			debug Stdout.formatln("{} <> {}:{}", key, node.key, res);
			if(res == 0) {
				node.map.list.add(t);
				return;
			}
			else if(res < 0) {
				if(last) {
					auto temp = node;
					node =  cast(Node*)Alloc.allocate(Node.sizeof);
					memset(node, 0, Node.sizeof);
					node.next = temp;
					node.key = key;
					node.map.list.add(t);
					last.next = node;
					return;
				}
				else {
					debug assert(node == first);
					auto temp = first;
					first =  cast(Node*)Alloc.allocate(Node.sizeof);
					memset(first, 0, Node.sizeof);
					first.next = temp;
					first.key = key;
					first.map.list.add(t);
					return;
				}
			}
			last = node;
			node = node.next;
		}
		if(last) {
			node = cast(Node*)Alloc.allocate(Node.sizeof);
			memset(node, 0, Node.sizeof);
			node.next = null;
			node.key = key;
			node.map.list.add(t);
			last.next = node;
		}
		else {
			first = cast(Node*)Alloc.allocate(Node.sizeof);
			memset(first, 0, Node.sizeof);
			first.next = null;
			first.key = key;
			first.map.list.add(t);
		}+/
		auto node = getNode(key);
		node.map.list.add(t);
	}
	
	void add(char[] key, char[] subkey, T t)
	{
		auto node = getNode(key);
		node.map.add(subkey, t);
	}
	
	void merge(SimpleList!(T, Alloc) l)
	{
		if(!l.first) return;
		
		auto node = list.first;
		while(1) {
			if(!node.next) {
				node.next = l.first;
				break;
			}
			else node = node.next;
		}
	}
	
	void merge(NestedMap!(T, Alloc) map)
	{
		if(map.list.first) merge(map.list);
		
		foreach(k, v; map)
		{
			auto node = getNode(k);
			node.map.merge(v);
		}
	}
	
	void merge(char[] key, SimpleList!(T, Alloc) l)
	{
		auto node = getNode(key);
		node.map.merge(l);
	}
	
	void merge(char[] key, NestedMap!(T, Alloc) map)
	{
		auto node = getNode(key);
		node.map.merge(map);
	}	
	
	void reset()
	{
		list.reset;
		first = null;
	}
	
	int opApply(int delegate(inout T t) dg)
	{
		return list.opApply(dg);
	}
	
	int opApply(int delegate(inout char[] key, inout NestedMap!(T, Alloc) map) dg)
	{
		int res = 0;
		auto node = first;
		while(node) {
			if((res = dg(node.key, node.map)) != 0) return res;
			node = node.next;
		}
		return res;
	}
	
	ForwardIterator getIterator()
	{
		ForwardIterator itr;
		itr.cur = first;
		return itr;
	}
	
	bool empty()
	{
		return first is null && list.empty;
	}
	
	debug static char[] print(NestedMap!(T, Alloc) map) {
		char[] res;

		void doMap(NestedMap!(T, Alloc) m, uint indent = 0)
		{
			char[] tabs() { char[] t; for(uint i = 0; i < indent; ++i) t ~= "\t"; return t; }

			foreach(x; m)
			{
				res ~= tabs ~ to!(char[])(x) ~ "\n";
			}
			
			foreach(key, value; m)
			{
				res ~= tabs ~ key ~ "\n";
				//foreach(x; value)
				//	res ~= "\t" ~ x ~ "\n";
				
				doMap(value, indent + 1);
			}
		}
		
		doMap(map);
		
		return res;
	}
}



debug(SenderoUnittest)
{
import sendero.core.Memory;
import tango.io.Stdout;
import qcf.Regression;
	
unittest
{
	NestedMap!(int, DefaultAllocator) map;
	map.reset;
	map.add("test", 5);
	map.add("bob", 4);
	map.add("bob", 4);
	map.add("aaron", 3);
	map.add("aaron", 4);
	map.add("aaron", 14);
	map.add("john", 7);
	map.add("john", "joe", 3);
	map.add(1);
	map.add(2);
	map.add(3);

	auto r = new Regression("msg");
	r.regress("nested_map.txt", map.print(map));
}
}