/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.msg.Msg;

import tango.core.Thread;

public import sendero.util.collection.NestedMap;
public import sendero.util.collection.SimpleList;
import sendero.core.Memory;

public alias NestedMap!(Msg, SessionAllocator) MsgMap;
public alias SimpleList!(Msg, SessionAllocator) MsgList;

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
	
	char[][char[]] getProperties()
	{
		return null;
	}
	
	static uint getClassID(char[] classname)
	{
		auto pCl = classname in registeredClasses;
		if(!pCl) return 0;
		return pCl.id;
	}
	
	static uint getParentID(uint id)
	{
		auto pCl = id in registeredClassesByID;
		if(pCl) return pCl.parent;
		return 0;
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
	
	private static ThreadLocal!(MsgMap) msgMaps;
	static this()
	{
		msgMaps = new ThreadLocal!(MsgMap);
	}
	
	static void set(Msg msg)
	{
		auto map = msgMaps.val;
		map.add(msg);
		msgMaps.val = map;
	}
	
	static void set(MsgList msgList)
	{
		auto map = msgMaps.val;
		msgMaps.val.merge(msgList);
		msgMaps.val = map;
	}
	
	static void set(MsgMap msgMap)
	{
		auto map = msgMaps.val;
		msgMaps.val.merge(msgMap);
		msgMaps.val = map;
	}
	
	static void set(char[] scope_, Msg msg)
	{
		auto map = msgMaps.val;
		msgMaps.val.add(scope_, msg);
		msgMaps.val = map;
	}
	
	static void set(char[] scope_, MsgList msgList)
	{
		auto map = msgMaps.val;
		msgMaps.val.merge(scope_, msgList);
		msgMaps.val = map;
	}
	
	static void set(char[] scope_, MsgMap msgMap)
	{
		auto map = msgMaps.val;
		msgMaps.val.merge(scope_, msgMap);
		msgMaps.val = map;
	}
	
	alias set post;
	
	static MsgMap read()
	{
		return msgMaps.val;
	}
	
	static void clear()
	{
		msgMaps.val.reset;
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

version(Unittest)
{
	import tango.util.Convert;
	import tango.io.Stdout;
	
	unittest
	{
		Msg.clear;
		Stdout("before post").newline;
		Msg.set(new Success);
		Stdout("after post").newline;
		auto map = Msg.read;
		Msg[] res;
		foreach(msg; map) {
			Stdout(msg.toString);
			res ~= msg;
		}
		assert(res.length == 1, to!(char[])(res.length));
	}
}