/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.msg.Msg;

import tango.core.Thread;

import sendero_base.Core;
import sendero_base.util.collection.Hash;

import sendero.core.Memory;
import sendero.vm.Bind;

/**
 * 
 */
class Msg : SessionObject
{	
	private this(char[] msgId, Var[] params, Msg parent = null)
	{
		msgId_ = msgId;
		params_ = params;
		if(parent !is null) {
			this.list_ = parent.list_;
			this.parent_ = parent;
		}
		else this.list_ = new MsgList(this);
	}
	
	//
	final char[] msgId() { return msgId_; }
	private char[] msgId_;
	
	//
	final Var[] params() { return params_; }
	private Var[] params_;
	
	//
	final char[] classname() { return classname_; }
	private char[] classname_;
	
	//
	final char[] fieldname() { return fieldname_; }
	private char[] fieldname_;
	
	private Msg append(Var[] p)
	{
		next_ = new Msg(this.msgId, p, this);
		return next_;
	}
	
	private Msg parent_ = null;
	private Msg next_ = null;
	
	static private class MsgList {
		private this(Msg head) { this.head = head; }
		Msg head;
	}
	
	private MsgList list_;
	
	invariant
	{
		assert(list_ !is null);
	}
	
	private Msg remove()
	in {
		assert(list_.head !is null);
	}
	body {
		if(this == list_.head) {
			debug assert(parent_ is null);
			list_.head = next_;
			if(next_ !is null) next_.parent_ = null;
			return next_;
		}
		else {
			debug assert(list_ !is null && this != list_.head);
			debug assert(parent_ !is null);
			parent_.next_ = next_;
			if(next_ !is null) next_.parent_ = parent_;
			return next_;
		}
	}
	
	//
	final Object handler() { return handler_; }
	
	//
	final bool handle(Object obj) {
		if(handler_ is null) {
			handler_ = obj;
			return true;
		}
		else if(handler_ == obj) return true;
		else return false;
	}
	private Object handler_;
	
	//
	static MsgSignature[] signatures;
	
	version(DDoc) {
		/**
		 * Posts a msg with id msgId and variadic arguments.
		 * 
		 * Example:
		 * ---
		 * Post.msg!("UnknownUser")("bob");
		 * ---
		 * 
		 * MsgId is a template parameter so that all
		 * known messages id's can be tracked by hidden static
		 * constructors.
		 *
		 */
		static void post(char[] msgId)(...)
		{
			
		}
	}
	else {
		static struct post(char[] msgId)
		{
			static void opCall(ParamsT...)(ParamsT params)
			{
				debug MsgSignatureCollector!(msgId,ParamsT) sig;
				Var[] vParams;
				vParams.length = ParamsT.length;
				foreach(idx,ParamT; ParamsT)
				{
					bind(vParams[idx],params[idx]);
				}
				MsgMap.post(msgId,vParams);
			}
		}
	}
}
/**
 * Alias for Msg
 */
alias Msg Error;

static struct ClassFieldPost(char[] msgId, char[] classname, char[] fieldname)
{
	static void opCall(ParamsT...)(ParamsT params)
	{
		debug MsgClassFieldSignatureCollector!(msgId,classname,fieldname,ParamsT) sig;
		Var[] vParams;
		vParams.length = ParamsT.length;
		foreach(idx,ParamT; ParamsT)
		{
			bind(vParams[idx],params[idx]);
		}
		MsgMap.postFor(classname, fieldname, msgId,vParams);
	}
}

/**
 * 
 */
class MsgMap : SenderoMap!(Msg)
{
	static this()
	{
		msgMaps = new ThreadLocal!(MsgMap);
	}
	private static ThreadLocal!(MsgMap) msgMaps;
	
	protected static MsgMap getInst()
	out(result) {
		assert(result !is null);
	}
	body {
		auto map = msgMaps.val;
		if(map is null) {
			map = new MsgMap;
			msgMaps.val = map;
		}
		return map;
	}
	
	protected static Msg post(char[] msgId, Var[] params)
	{
		auto inst = getInst;
		auto pMsg = msgId in inst;
		if(pMsg) {
			*pMsg = (*pMsg).append(params);
			return *pMsg;
		}
		else {
			auto msg = new Msg(msgId,params);
			inst.add(msgId, msg);
			return msg;
		}
	}
	
	protected static Msg postFor(char[] classname, char[] fieldname, char[] msgId, Var[] params)
	{
		auto msg = post(msgId,params);
		msg.classname_ = classname;
		msg.fieldname_ = fieldname;
		return msg;
	}
	
	/**
	 * Clears all messages from the message list
	 *
	 */
	static void clear()
	{
		auto inst = getInst;
		//TODO this should be inst.clear - but that hangs
		if(!inst.isEmpty) inst.reset;
	}
	
	/**
	 * 
	 * Params:
	 *     readDg = delegate to receieve messages that have been sent,
	 *     	returns true if it has read the message and wants it deleted
	 *     	from the list of messages
	 */
	static void read(bool delegate(char[] msgId, Msg msg) readDg)
	{
		auto itr = getInst.iterator;
		char[] key;
		Msg pMsg;
		while(itr.next(key,pMsg)) {
			auto msg = pMsg.list_.head;
			auto list = pMsg.list_;
			do {
				Stdout.formatln("Sending {}",msg.msgId);
				if(readDg(key,msg)) {
					msg = msg.remove;
				}
				else msg = msg.next_;
			} while(msg !is null)
			if(list.head is null) itr.remove;
			else pMsg = list.head;
		}
	}
	
	/**
	 * Reads messages for the class specified 
	 * 
	 * Params:
	 *     classname = name of the class to receive messages for
	 *     readDg = see above
	 */
	static void read(char[] classname, bool delegate(char[] msgId, Msg msg) readDg)
	{
		read(classname, null, readDg);
	}
	
	/**
	 * /**
	 * Reads messages for the class and field specified 
	 * 
	 * Params:
	 *     classname = name of the class to receive messages for
	 *     fieldname = name of the field to receive messages for
	 *     readDg = see above
	 */
	static void read(char[] classname, char[] fieldname, bool delegate(char[] msgId, Msg msg) readDg)
	{
		auto itr = getInst.iterator;
		char[] key;
		Msg pMsg;
		while(itr.next(key,pMsg)) {
			auto msg = pMsg.list_.head;
			auto list = pMsg.list_;
			do {
				if(msg.classname == classname &&
					(!fieldname.length || msg.fieldname == fieldname)) {
					if(readDg(key,msg)) {
						msg = msg.remove;
					}
					else msg = msg.next_;
				}
				else msg = msg.next_;
			} while(msg !is null)
			if(list.head is null) itr.remove;
			else pMsg = list.head;
		}
	}
}

/**
 * 
 */
struct MsgSignature
{
	//
	char[] id;
	//
	char[] params;
	//
	char[] classname;
	//
	char[] fieldname;
}

struct MsgSignatureCollector(char[] msgId, ParamsT...)
{
	static this()
	{
		Msg.signatures ~= MsgSignature(msgId,ParamsT.stringof);
	}
}

struct MsgClassFieldSignatureCollector(char[] msgId, char[] className, char[] fieldName, ParamsT...)
{
	static this()
	{
		Msg.signatures ~= MsgSignature(msgId,ParamsT.stringof,className,fieldName);
	}
}


debug(SenderoUnittest)
{
	import tango.io.Stdout;
	
	class Test
	{
		template postMsg(char[] msgId, char[] fieldname = null) {
			alias ClassFieldPost!(msgId,"Test",fieldname) postMsg;
		}
		alias postMsg postError;
		
		void test()
		{
			postError!("TestClassError")(1);
			postError!("TestClassFieldError","x")(1);
		}

		int x;
	}
	
	unittest
	{
		// Test posting and retrieval
		MsgMap.clear;
		Msg.post!("TestMsg")(5);
		Msg.post!("TestMsg")(7,"hello");
		/+auto msg = MsgMap.capture("TestMsg");
		assert(msg !is null);
		assert(msg.params.length == 1);
		assert(msg.params[0].type == VarT.Number && msg.params[0].number_ == 5);
		msg = msg.next;
		assert(msg !is null);
		assert(msg.params.length == 2);
		assert(msg.params[0].type == VarT.Number && msg.params[0].number_ == 7);
		assert(msg.params[1].type == VarT.String && msg.params[1].string_ == "hello", msg.params[1].string_);
		assert(msg.next is null);+/
		
//		Test class-field messages
		auto test = new Test;
		test.test;
		
		int count = 0;
		MsgMap.read((char[] id, Msg msg) {
			Stdout.formatln("Got {}",id);
			if(id == "TestMsg") {
				++count;
				return true;
			}
			else return false;
		});
		assert(count == 2);
		
		count = 0;
		MsgMap.read((char[] id, Msg msg) {
			Stdout.formatln("Got {}",id);
			++count;
			return false;
		});
		assert(count == 2);
		count = 0;
		MsgMap.read("Test",(char[] id, Msg msg) {
			Stdout.formatln("Got {}",id);
			++count;
			return false;
		});
		assert(count == 2);
		count = 0;
		MsgMap.read("Test","x",(char[] id, Msg msg) {
			++count;
			return false;
		});
		assert(count == 1);
		count = 0;
		MsgMap.read("User","name",(char[] id, Msg msg) {
			++count;
			return false;
		});
		assert(count == 0);
		
		// Test signatures
		int found = 0;
		foreach(sig; Msg.signatures)
		{
			//Stdout.formatln("{}:{}",sig.id,sig.params);
			if(sig.id == "TestMsg") {
				if(sig.params == "(int)") ++found;
				if(sig.params == "(int, char[5u])") ++found;
			}
			if(sig.id == "TestClassError") {
				assert(sig.params == "(int)");
				assert(sig.classname == "Test");
				assert(sig.fieldname == "");
				++found;
			}
			if(sig.id == "TestClassFieldError") {
				assert(sig.params == "(int)");
				assert(sig.classname == "Test");
				assert(sig.fieldname == "x");
				++found;
			}
		}
		assert(found == 4);
	}
}