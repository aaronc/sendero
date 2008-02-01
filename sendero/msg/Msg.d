module sendero.msg.Msg;

import tango.core.Thread;

abstract class Msg
{
	static uint registerClass(char[] classname)
	{
		synchronized
		{
			auto pCl = classname in registeredClasses;
			if(!pCl) {
					auto reg = new ClassRegistration;
					reg.id = registeredClasses.length + 1;
					reg.cls = classname;
					registeredClasses[classname] = reg;
					registeredClassesByID[reg.id] = reg;
					return reg.id;
			}
			return pCl.id;
		}
	}
	
	void register(char[] classname)
	{
		auto pCl = classname in registeredClasses;
		if(pCl) {
			id = pCl.id;
			return;
		}
		auto x = registerClass(classname);
		if(id) {
			pCl = classname in registeredClasses;
			if(!pCl) throw new Exception("Unable to find classname after registering");
			pCl.parent = id;
		}
		id = x;
	}
	
	static uint getClassID(char[] classname)
	{
		auto pCl = classname in registeredClasses;
		if(!pCl) return 0;
		return pCl.id;
	}
	
	static char[] getClassName(uint id)
	{
		auto pCl = id in registeredClassesByID;
		if(pCl) return pCl.cls;
		return null;
	}
	
	static ClassRegistration getClassReg(uint id)
	{
		auto pCl = id in registeredClassesByID;
		if(pCl) {
			return *pCl;
		}
		return null;
	}
	
	static class ClassRegistration
	{
		uint id;
		uint parent = 0;
		char[] cls;
	}
	
	static ClassRegistration[char[]] registeredClasses;
	static ClassRegistration[uint] registeredClassesByID;
	
	private static ThreadLocal!(Mailbox) mailboxes;
	static this()
	{
		mailboxes = new ThreadLocal!(Mailbox);
	}
	
	static void post(Msg msg)
	{
		mailboxes.val.post(msg);
	}
	
	static void post(char[] scope_, Msg msg)
	{
		mailboxes.val.post(scope_, msg);
	}
	
	static void post(MsgMap msgMap)
	{
		mailboxes.val.post(msgMap);
	}
	
	static void post(char[] scope_, MsgMap msgMap)
	{
		mailboxes.val.post(scope_, msgMap);
	}
	
	static Mailbox read()
	{
		return mailboxes.val;
	}
	
	static void clear()
	{
		mailboxes.val.clear;
	}
	
	uint id = 0;
	
	debug uint[] idTree()
	{
		auto pCl = id in registeredClassesByID;
		assert(pCl);
		uint[] res;
		assert(pCl.id == id);
		res ~= pCl.id;
		auto cr = getClassReg(pCl.parent);
		while(cr) {
			res ~= cr.id;
			cr = getClassReg(cr.parent);
		}
		return res;
	}
	
	debug char[][] clsTree()
	{
		auto ids = idTree;
		char[][] res;
		foreach(id; ids)
			res ~= getClassName(id);
		return res;
	}
}

alias Msg[][char[]] MsgMap;

struct Mailbox
{
	Msg[] msgs;
	Mailbox[char[]] scopedMsgs;
	
	void clear()
	{
		msgs = null;
		scopedMsgs = null;
	}
	
	void post(Msg msg)
	{
		msgs ~= msg;
	}
	
	void post(char[] scope_, Msg msg)
	{
		scopedMsgs[scope_].msgs ~= msg;
	}
	
	void post(MsgMap msgMap)
	{
		foreach(k, v; msgMap)
		{
			scopedMsgs[k].msgs ~= v;
		}
	}
	
	void post(char[] scope_, MsgMap msgMap)
	{
		scopedMsgs[scope_].post(msgMap);
	}
}

class Success : Msg
{
	this()
	{
		register("Success");
	}
}

class CreateSuccess : Success
{
	this()
	{
		register("CreateSuccess");
	}
}

class SaveSuccess : Success
{
	this()
	{
		register("SaveSuccess");
	}
}

class FieldMsgs : Msg
{
	this(char[] field, Msg[] msgs)
	{
		register("FieldMsgs");
		this.field = field;
		this.msgs = msgs;
	}
	char[] field;
	Msg[] msgs;
}