/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.db.SqlGen;

public import sendero.util.Reflection;

char[] createInsertSql(T, char quote = '\'')(char[][] except = null, char[] tablename = null)
{
	auto fields = getFieldNames!(T)(except);
	if(!tablename.length) tablename = T.stringof;
	return makeInsertSql(tablename, fields, quote);
}

char[] createUpdateSql(T, char quote = '\'')(char[] whereClause, char[][] except = null, char[] tablename = null)
{
	auto fields = getFieldNames!(T)(except);
	if(!tablename.length) tablename = T.stringof;
	return makeUpdateSql(whereClause, tablename, fields, quote);
}

char[] makeInsertSql(char[] tablename, char[][] items, char quote = '\'')
{
	if(!items.length) throw new Exception("Trying to make INSERT SQL but no fields were provided");
	
	char[] res = "INSERT into " ~ quote ~ tablename ~ quote ~ " (";
	res ~= makeList(items, quote) ~ ") VALUES(";
	auto len = items.length;
	for(uint i = 0; i < len; ++i)
	{
		res ~= "?,";
	}
	res[$ - 1] = ')';
	return res;
}

char[] makeUpdateSql(char[] whereClause, char[] tablename, char[][] fields, char quote = '\'')
{
	if(!fields.length) throw new Exception("Trying to make INSERT SQL but no fields were provided");
	
	char[] res = "UPDATE '" ~ quote ~ tablename ~ quote ~ "' SET ";
	foreach(f; fields)
	{
		res ~= quote ~ f ~ quote ~ "=\?,";
	}
	res[$-1] = ' ';
	if(whereClause.length) res ~= whereClause;
	return res;
}

char[] makeList(char[][] items, char quote = '\'')
{
	char[] res;
	
	foreach(x; items)
	{
		res ~= quote ~ x ~ quote ~ ",";
	}
	
	return res[0 .. $ - 1];
}

char[] createFieldList(T)(char[][] except)
{
	auto fields = getFieldNames!(T)(except);
	returen makeList(fields);
}

char[][] getFieldNames(T)(char[][] except)
{
	char[][] res;
	auto fields = ReflectionOf!(T).fields;
	auto len = fields.length;
	for(uint i = 0; i < len; ++i)
	{
		bool skip = false;
		foreach(n; except) if(fields[i].name == n) skip = true;
		if(skip) continue;
		res ~= fields[i].name;
	}
	return res;
}

template SelectList(char[] n) {
	const char[] SelectList = "static if(T.length > " ~ n ~ ") {"
		"fields = ReflectionOf!(T[" ~ n ~ "]).fields;"
		"foreach(f; fields) {"
			"res ~= \"'\" ~ T[" ~ n ~ "].stringof ~ \"'.'\" ~ f.name ~ \"',\";"
		"}"
	"}";
}

char[] createJoinSelectList(T...)()
{
	char[] res;
	sendero.util.FieldInfo.FieldInfo[] fields;
	
	/+static if(T.length > 0) {
		fields = ReflectionOf!(T[0]).fields;
		foreach(f; fields) {
			res ~= "'" ~ T[0].stringof ~ "'.'" ~ f.name ~ "',";
		}
	}+/
	
	mixin(SelectList!("0"));
	mixin(SelectList!("1"));
	mixin(SelectList!("2"));
	mixin(SelectList!("3"));
	mixin(SelectList!("4"));
	mixin(SelectList!("5"));
	mixin(SelectList!("6"));
	mixin(SelectList!("7"));
	static if(T.length > 8) static assert(false);
	
	return res[0 .. $ - 1];
}

unittest
{
	static class Test
	{
		int a;
		double b;
		char[] c;
	}
	
	static class Test2
	{
		uint y;
		void[] z;
	}
	
	auto select = createJoinSelectList!(Test, Test2)();
	assert(select == "'Test'.'a','Test'.'b','Test'.'c','Test2'.'y','Test2'.'z'", select);
}

