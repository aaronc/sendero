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

class Msg : SessionObject
{	
	private this(char[] msgId, Var[] params, Msg parent = null)
	{
		msgId_ = msgId;
		params_ = params;
		if(parent !is null) {
			this.head_ = parent.head_;
		}
		else this.head_ = this;
	}
	
	final char[] msgId() { return msgId_; }
	private char[] msgId_;
	
	final Var[] params() { return params_; }
	private Var[] params_;
	
	private Msg append(Var[] p)
	{
		next_ = new Msg(this.msgId, p, this);
		return next_;
	}
	
	final Msg next() { return next_; }
	private Msg next_ = null;
	
	final Msg head() { return head_; }
	private Msg head_ = null;
	
	static MsgSignature[] signatures;
	
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
alias Msg Error;

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
	
	protected static void post(char[] msgId, Var[] params)
	{
		auto inst = getInst;
		auto pMsg = msgId in inst;
		if(pMsg) {
			*pMsg = (*pMsg).append(params);
		}
		else inst.add(msgId, new Msg(msgId,params));
	}
	
	static Msg retrieve(char[] msgId)
	{
		Msg res;
		if(getInst.take(msgId,res)) {
			return res.head;
		}
		else return null;
	}
	
	static void clear()
	{
		auto inst = getInst;
		if(!inst.isEmpty) inst.clear;
	}
}

struct MsgSignature
{
	char[] id;
	char[] params;
}

struct MsgSignatureCollector(char[] msgId, ParamsT...)
{
	static this()
	{
		Msg.signatures ~= MsgSignature(msgId,ParamsT.stringof);
	}
}

debug(SenderoUnittest)
{
	//import tango.io.Stdout;
	
	unittest
	{
		// Test posting and retrieval
		MsgMap.clear;
		Msg.post!("TestMsg")(5);
		Msg.post!("TestMsg")(7,"hello");
		auto msg = MsgMap.retrieve("TestMsg");
		assert(msg !is null);
		assert(msg.params.length == 1);
		assert(msg.params[0].type == VarT.Number && msg.params[0].number_ == 5);
		msg = msg.next;
		assert(msg !is null);
		assert(msg.params.length == 2);
		assert(msg.params[0].type == VarT.Number && msg.params[0].number_ == 7);
		assert(msg.params[1].type == VarT.String && msg.params[1].string_ == "hello", msg.params[1].string_);
		assert(msg.next is null);
		
		// Test signatures
		int found = 0;
		foreach(sig; Msg.signatures)
		{
			//Stdout.formatln("{}:{}",sig.id,sig.params);
			if(sig.id == "TestMsg") {
				if(sig.params == "(int)") ++found;
				if(sig.params == "(int, char[5u])") ++found;
			}
		}
		assert(found == 2);
	}
}