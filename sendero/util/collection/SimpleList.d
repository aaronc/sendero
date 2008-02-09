module sendero.util.collection.SimpleList;

import sendero.core.Memory;

struct SimpleList(T, Alloc = DefaultAllocator)
{
	Node* first;
	
	struct Node
	{
		T t;
		Node* next;
	}
	
	void add(T x)
	{
		auto node = cast(Node*)Alloc.allocate(Node.sizeof);
		node.t = x;
		if(first) {
			auto temp = first;
			node.next = temp;
			first = node;
		}
		else {
			first = node;
			first.next = null;
		}
	}
	alias add opCatAssign;
	
	int opApply(int delegate(inout T t) dg)
	{
		int res = 0;
		auto node = first;
		while(node) {
			if((res = dg(node.t)) != 0) return res;
			node = node.next;
		}
		return res;
	}
	
	void reset()
	{
		first = null;
	}
}

version(Unittest)
{
import tango.core.Memory;

struct Alloc
{
	static void* allocate(size_t sz)
	{
		return GC.malloc(sz);
	}
}
	
unittest
{
	SimpleList!(int, Alloc) list;
	list.add(5);
	list.add(7);
	list.add(3);
	int[] res;
	foreach(x; list)
	{
		res ~= x;
	}
	assert(res[0] == 3);
	assert(res[1] == 7);
	assert(res[2] == 5);
}
}