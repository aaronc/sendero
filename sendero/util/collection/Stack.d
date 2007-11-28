module sendero.util.collection.Stack;

/**
 * Implements a very simple FILO stack
 */
class Stack(T)
{
	this()
	{
		head = null;
		tail = null;
		count_ = 0;
	}
	
	static class Cell(T)
	{
		this(T t)
		{
			this.t = t;
			this.next = null;
			this.prev = null;
		}
		T t;
		Cell!(T) next;
		Cell!(T) prev;
	}
	
	Cell!(T) head;
	Cell!(T) tail;
	protected uint count_;
	
	uint count()
	{
		return count_;
	}
	
	bool empty()
	{
		return count_ == 0 ? true : false;
	}

	T top()
	{
		if(tail !is null)
		{
			return tail.t;
		}
		return T.init;
	}
	
	void pop()
	{
		if(tail !is null)
		{
			if(tail.prev !is null)
			{
				auto cell = tail.prev;
				cell.next = null;
				tail = cell;
			}
			else
			{
				tail = null;
				head = null;
			}
			--count_;
		}
	}
	
	void push(T token)
	{
		if(head is null)
		{
			head = new Cell!(T)(token);
			tail = head;
		}
		else
		{
			auto cell = new Cell!(T)(token);
			tail.next = cell;
			cell.prev = tail;
			tail = cell;
		}
		++count_;
	}
	
	alias push opCatAssign;
}

unittest
{
	auto stack = new Stack!(int);
	
	assert(stack.empty);
	assert(stack.count == 0);
	stack.push(5);
	stack.push(7);
	stack.push(14);
	stack ~= 9;
	assert(stack.top == 9);
	stack.pop;
	assert(stack.top == 14);
	assert(stack.count == 3);
	assert(!stack.empty);
	stack.pop;
	assert(stack.top == 7);
	stack.push(3);
	assert(stack.top == 3);
	assert(!stack.empty);
	stack.pop;
	assert(stack.top == 7);
	assert(stack.count == 2);
	stack.pop;
	assert(stack.top == 5);
	assert(stack.count == 1);
	stack.pop;
	assert(stack.empty);
	assert(stack.count == 0);
}