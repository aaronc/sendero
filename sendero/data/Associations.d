/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.data.Associations;

import sendero.data.model.IDBConnection;
import sendero.data.DB;

import tango.core.Array;

/*
 * Template struct for creating HasOne relationships:
 * 
 * Usage:
 * ---
 * 	class User
 * 	{
 * 		PrimaryKey id;
 * 		char[] username;
 * 		HasOne!(Group) group;
 * 	}
 * ---
 * 
 * That's it!  Sendero takes care of the rest.
 */
struct HasOne(T)
{
	package IDBConnection db;
	private T t;
	alias T type;
	package ulong id = 0;
	
	void opAssign(T t)
	{
		this.t = t;
		this.id = t.id();
	}
	
	T get()
	{
		if(t) {
			return t;
		}
		static if(is(typeof(T.findByID))) {
			if(id) {
				t = T.findByID(id);
				return t;
			}
		}
		else {
			if(id && db) {
				scope cs = new DBSerializer!(T)(db);
				t = cs.findByID(id);
				return t;
			}
		}
		return null;
	}
}

/*
 * Template struct for creating HABTM (Has and Belongs to Many) relationships where T represents
 * the object of the association and J represents the join table.  J can either be an instantiation of the
 * built-in class template JoinTable!(X, Y) or a derived class of JoinTable!(X, Y);
 * 
 * Example 1:
 * ---
 * 	class UsersGroups : JoinTable!(User, Group)
	{
		char[] relationship;
	}
	
 * 	class User
	{
		HABTM!(Group, UsersGroups) groups;
		char[] username;
		void[] password_hash;
		PrimaryKey id;
	}
	
	class Group
	{
		PrimaryKey id;
		char[] name;
		HABTM!(User, UsersGroups) users;
	}
 * ---
 * 
 * Example 2:
 * ---
 * 	class Artist
 * 	{
 * 		PrimaryKey id;
 * 		char[] name;
 * 		HABTM!(Song, JoinTable!(Artist, Song)) songs;
 * 	}
 * 
 * 	class Song
 * 	{
 * 		PrimaryKey id;
 * 		char[] name;
 * 		HABTM!(Artist, JoinTable!(Artist, Song)) artists;
 * 	}
 * 	---
 * 
 * The join table must be the same for both sides of the relationship (i.e. do not write JoinTable!(Artist, Song)
 * in one class and JoinTable!(Song, Artist) in the other - this will NOT work properly.
 * 
 * That's it!  Sendero takes care of the rest.
 */
struct HABTM(T, J)
{	
	alias T type;
	alias J joinType;
	
	struct Pair
	{
		T val;
		J join;
	}
	private Pair[] data;
	private bool loaded = false;
	private bool modified = false;
	
	Pair[] get()
	{
		if(!loaded)
		{
			load;
		}
		return data;
	}
	
	Pair opCatAssign(T t)
	{
		if(!t.id()) {
			throw new Exception("Object of type" ~ T.stringof ~ " must be saved before it is added to a HABTM collection");
		}
		
		foreach(p; data)
		{
			if(p.val.id() == t.id())
				return p;
		}
		
		Pair p;
		p.val = t;
		p.join = new J;
		static if(is(J.__x == T)) {
			p.join.xID = t.id();
		}
		else static if(is(J.__y == T)) {
			p.join.yID = t.id();
		}
		else assert(false);
		data ~= p;
		modified = true;
		return p;
	}
	
	void remove(T t)
	{
		assert(false);
	}
	
	package ulong id = 0;
	package IDBConnection db = null;
	
	private void load()
	{
		if(id == 0)
			return;
		
		static if(is(J.__x == T)) {
			static if(is(typeof(J.findByYID))) {
				assert(false, "Not implemented yet");
			}
			else {
				if(!db)
					throw new Exception("Trying to load join table " ~ J.stringof ~ " in HABTM but no database has been set");
				scope cs = new DBSerializer!(J)(db);
				scope tCS = new DBSerializer!(T)(db);
				auto f = cs.findWhere!(ulong)("yID = ?");
				auto res = f.find(id);
				J j;
				while((j = res.next) !is null)
				{
					Pair p;
					p.join = j;
					p.val = tCS.findByID(j.xID);
					data ~= p;
				}
			}
		}
		else static if(is(J.__y == T)) {
			static if(is(typeof(J.findByXID))) {
				assert(false, "Not implemented yet");
			}
			else {
				if(!db)
					throw new Exception("Trying to load join table " ~ J.stringof ~ " in HABTM but no database has been set");
				scope cs = new DBSerializer!(J)(db);
				scope tCS = new DBSerializer!(T)(db);
				auto f = cs.findWhere!(ulong)("xID = ?");
				auto res = f.find(id);
				J j;
				while((j = res.next) !is null)
				{
					Pair p;
					p.join = j;
					p.val = tCS.findByID(j.yID);
					data ~= p;
				}
			}
		}
		else assert(false);
		loaded = true;
	}
	
	package void save(ulong id)
	{
		if(!modified)
			return;
		
		foreach(p; data)
		{
			static if(is(J.__x == T)) {
				p.join.yID = id;
			}
			else static if(is(J.__y == T)) {
				p.join.xID = id;
			}
			else assert(false);
		}	
		
		static if(is(typeof(J.save)))
		{
			foreach(p; data)
				p.save;
		}
		else {
			if(!db)
				throw new Exception("Trying to save join table " ~ J.stringof ~ " in HABTM but no database has been set");
			scope cs = new DBSerializer!(J)(db);
			foreach(p; data)
				cs.save(p.join);
		}
		
		modified = false;
	}
}

class JoinTable(X, Y)
{
	alias X __x;
	alias Y __y;
	PrimaryKey id;
	uint xID;
	uint yID;
}

version(Unittest)
{
	class TestA
	{
		PrimaryKey id;
		uint x;
	}
	
	class TestB
	{
		PrimaryKey id;
		HasOne!(TestA) a;
	}
	
	class BC : JoinTable!(TestB, TestC)
	{
		int x;
	}
	
	class TestC
	{
		PrimaryKey id;
		HABTM!(TestB, BC) b;
	}
	
	import sendero.util.Reflection;
}

unittest
{
	assert(TableDescriptionOf!(TestB).columns[1].type == ColT.HasOne);
	
	assert(ReflectionOf!(BC).fields[0].name == "id", ReflectionOf!(BC).fields[0].name);
	assert(ReflectionOf!(BC).fields[1].name == "xID", ReflectionOf!(BC).fields[1].name);
	assert(ReflectionOf!(BC).fields[2].name == "yID", ReflectionOf!(BC).fields[2].name);
	assert(ReflectionOf!(BC).fields[3].name == "x", ReflectionOf!(BC).fields[3].name);
}