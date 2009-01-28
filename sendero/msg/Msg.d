/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.msg.Msg;

import tango.core.Thread;

import sender_base.util.collection.Hash;

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
	
	char[] msgId() { return msgId; }
	private char[] msgId_;
	
	Var[] params() { return params_; }
	private Var[] params_;
	
	protected Msg append(Var[] p)
	{
		next_ = new Msg(this.msgId, p, this);
		return next_;
	}
	
	private Msg next_ = null
	private Msg head_ = null;
	
	static MsgSignature[] signatures;
	
	static struct post(char[] msgId)
	{
		static void opCall(ParamsT...)(ParamsT params)
		{
			debug MsgSignatureCollector!(id,ParamsT) sig;
			Var[] vParams;
			vParams.length = ParamsT.length;
			foreach(idx,param; params)
			{
				bind(vParams[idx],param);
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
		assert(res !is null);
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
			*pMsg = pMsg.append(params);
		}
		else inst.add(new Msg(msgId,param));
	}
	
	static Msg take(char[] msgId)
	{
		Msg res;
		if(getInst.take(msgId,res)) {
			return res;
		}
		else return null;
	}
	
	static void clear()
	{
		getInst.clear;
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
	
	unittest
	{

	}
}