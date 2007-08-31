/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.data.DB;

public import tango.core.Type;
public import tango.util.time.Date;
public import tango.util.time.DateTime;

import sendero.util.Reflection;
import sendero.data.model.IDBConnection;

import tango.util.log.Log;
debug import tango.io.Stdout;

package const int SQLRESULT_FAIL = -1;
package const int SQLRESULT_SUCCESS = 0;
package const int SQLRESULT_ROW = 1;

/**
 * Struct that represents the primary key in a database table.
 * In this version of Sendero, it is expected that all database tables
 * will contain a primary key named id;
 * 
 * Example:
 * ---
 * 	class Test
 * 	{
 * 		PrimaryKey id;
 * 	}
 */
struct PrimaryKey
{
	private uint key = 0;
	uint opCall()
	{
		return key;
	}
}

static class TableColumnVisitor
{
	this(char[] classname)
	{
		this.classname = classname;
	}
	
	char[] classname;
	ColumnInfo[] columns;
	bool hasAssociations = false;
	int primaryKeyIndex = -1;
	
	void visit(X)(X x, uint index)
	{
		auto info = new ColumnInfo;
		static if(is(X == bool)) {
			info.type = ColT.Bool;
		}
		else static if(is(X == ubyte)) {
			info.type = ColT.UByte;
		}
		else static if(is(X == byte)) {
			info.type = ColT.Byte;
		}
		else static if(is(X == ushort)) {
			info.type = ColT.UShort;
		}
		else static if(is(X == short)) {
			info.type = ColT.Short;
		}
		else static if(is(X == uint)) {
			info.type = ColT.UInt;
		}
		else static if(is(X == int)) {
			info.type = ColT.Int;
		}
		else static if(is(X == ulong)) {
			info.type = ColT.ULong;
		}
		else static if(is(X == long)) {
			info.type = ColT.Long;
		}
		else static if(is(X == float)) {
			info.type = ColT.Float;
		}
		else static if(is(X == double)) {
			info.type = ColT.Double;
		}
		else static if(is(X:char[])) {
			info.type = ColT.VarChar;
		}
		else static if(is(X:void[]) || is(X:ubyte[])) {
			info.type = ColT.Blob;
		}
		else static if(is(X == DateTime)) {
			info.type = ColT.DateTime;
		}
		else static if(is(X == PrimaryKey)) {
			info.primaryKey = true;
			info.type = ColT.UInt;
			primaryKeyIndex = index;
		}
		else static if(X.stringof.length >= 6 && X.stringof[0 .. 6] == "HasOne") {
			info.type = ColT.HasOne;
		}
		else static if(X.stringof.length >= 5 && X.stringof[0 .. 5] == "HABTM") {
			info.type = ColT.HABTM;
			info.skip = true;
			hasAssociations = true;
		}
		else static if(is(X == class) || is(X == struct)) {
			info.type = ColT.Object;
		}
		else assert(false, "Unable to determine column type for type " ~ X.stringof ~ " in class " ~ classname);
		
		columns ~= info;
	}
}

class TableDescriptionOf(T)
{
	static this()
	{
		static if(T.stringof.length >= 9 && T.stringof[0 .. 9] == "JoinTable") {
			tablename = T.x.stringof ~ T.y.stringof;
		}
		else {
			tablename =  T.stringof;
		}
		auto visitor = new TableColumnVisitor(T.stringof);
		auto t = new T;
		ReflectionOf!(T).visitTuple(t, visitor);
		columns = visitor.columns;
		hasAssociations = visitor.hasAssociations;
		primaryKeyIndex = visitor.primaryKeyIndex;
	}
	
	static const char[] tablename;
	static const ColumnInfo[] columns;
	static bool hasAssociations;
	static const int primaryKeyIndex;
}

class SetStatementBinder
{
	this(IPreparedStatement st)
	{
		this.st = st;
	}
	
	IPreparedStatement st;
	uint i = 0;
	
	void visit(X)(X x, uint index)
	{
		static if(is(X == int))
			st.bindInt(x, i);
		else static if(is(X == uint))
			st.bindUInt(x, i);
		else static if(is(X == long))
			st.bindLong(x, i);
		else static if(is(X == ulong))
			st.bindULong(x, i);
		else static if(is(X == ushort))
			st.bindUShort(x, i);
		else static if(is(X == short))
			st.bindShort(x, i);
		else static if(is(X == bool))
			st.bindBool(x, i);
		else static if(is(X == float))
			st.bindFloat(x, i);
		else static if(is(X == double))
			st.bindDouble(x, i);
		else static if(is (X: char[]))
			st.bindString(x, i);
		else static if(is(X == wchar[]))
			st.bindWString(x, i);
		else static if(is (X == void[]))
			st.bindBlob(x, i);
		else static if(is (X == ubyte[]))
			st.bindBlob(cast(void[])x, i);
		else static if(is (X == DateTime))
			st.bindDateTime(x, i);
		else static if(is(X == PrimaryKey)) {
			return;
		}
		else static if(X.stringof.length >= 6 && X.stringof[0 .. 6] == "HasOne") {
			st.bindULong(x.id, i);
		}
		else static if(X.stringof.length >= 5 && X.stringof[0 .. 5] == "HABTM") {
			return;
		}
		else assert(false, "Unhandled bind type");
		++i;
	}
}

class GetStatementBinder
{
	this(IPreparedStatement st, void* start, FieldInfo[] fields, IDBConnection db)
	{
		this.st = st;
		this.start = start;
		this.fields = fields;
		this.db = db;
	}
	
	IPreparedStatement st;
	uint i = 0;
	void* start;
	FieldInfo[] fields;
	IDBConnection db;
	
	void visit(X)(X _x, uint index)
	{
		X x;
		static if(is(X == int))
			st.getInt(x, i);
		else static if(is(X == uint))
			st.getUInt(x, i);
		else static if(is(X == long))
			st.getLong(x, i);
		else static if(is(X == ulong))
			st.getULong(x, i);
		else static if(is(X == ushort))
			st.getUShort(x, i);
		else static if(is(X == short))
			st.getShort(x, i);
		else static if(is(X == bool))
			st.getBool(x, i);
		else static if(is(X == float))
			st.getFloat(x, i);
		else static if(is(X == double))
			st.getDouble(x, i);
		else static if(is (X: char[]))
			st.getString(x, i);
		else static if(is(X == wchar[]))
			st.getWString(x, i);
		else static if(is (X == void[]))
			st.getBlob(x, i);
		else static if(is (X == ubyte[]))
			st.getBlob(cast(void[])x, i);
		else static if(is (X == DateTime))
			st.getDateTime(x, i);
		else static if(is(X == PrimaryKey)) {
			uint id;
			st.getUInt(id, i);
			x.key = id;
		}
		else static if(X.stringof.length >= 6 && X.stringof[0 .. 6] == "HasOne") {
			ulong id;
			st.getULong(id, i);
			x.id = id;
			x.db = db;
		}
		else static if(X.stringof.length >= 5 && X.stringof[0 .. 5] == "HABTM") {
			return;
		}
		else assert(false, "Unhandled bind type");
		*cast(X*)(start + fields[index].offset) = x;
		
		++i;
	}
}

class SetAssociated
{
	this(ulong id, IDBConnection db)
	{
		this.id = id;
		this.db = db;
	}
	ulong id;
	IDBConnection db;
	
	void visit(X)(X x, uint index)
	{
		static if(X.stringof.length >= 5 && X.stringof[0 .. 5] == "HABTM") {
			x.db = db;
			x.save(id);
		}
	}
}

class GetAssociated
{
	this(ulong id, void* start, FieldInfo[] fields, IDBConnection db)
	{
		this.id = id;
		this.start = start;
		this.fields = fields;
		this.db = db;
	}
	
	IPreparedStatement st;
	ulong id;
	void* start;
	FieldInfo[] fields;
	IDBConnection db;
	
	
	void visit(X)(X x_, uint index)
	{
		static if(X.stringof.length >= 5 && X.stringof[0 .. 5] == "HABTM") {
			X x;
			x.id = id;
			x.db = db;
			*cast(X*)(start + fields[index].offset) = x;
		}
	}
}

/**
 * Represents the results returned by a select query for object T.
 */
class ResultSet(T)
{
	private this(IPreparedStatement st, DBSerializer!(T) cs)
	{
		this.st = st;
		this.cs = cs;
	}
	
	void reset()
	{
		st.reset;
	}
	
	~this()
	{
		reset;
	}
	
	IPreparedStatement st;
	DBSerializer!(T) cs;
	
	/**
	 * Returns the next available T object in the result set or null if
	 * there are no more objects in the result set.
	 */
	T next()
	{
		if(st.execute == SQLRESULT_ROW) {
			return cs.deserialize(st);
		}
		return null;
	}
	
	T[] fetchNextN(uint n)
	{
		T[] res;
		uint i = 0;
		while(i < n) {
			auto t = next;
			if(!t)
				break;
			res ~= t;
		}
		return res;
	}
	
	T[] fetchAll()
	{
		T[] res;
		T t;
		while((t = next) != null)
			res ~= t;
		return res;
	}
}

/**
 * Class for finding objects with the specified prepared statement and specified bind objects.
 * Can be reused for as many queries as necessary.  Note: Interface subject to change in future versions.
 */
class Finder(T, X...)
{
	private this(IPreparedStatement st, DBSerializer!(T) cs)
	{
		this.st = st;
		this.cs = cs;
	}
	IPreparedStatement st;
	DBSerializer!(T) cs;
	
	ResultSet!(T) find(X x)
	{		
		st.reset;
		auto binder = new SetStatementBinder(st);
			
		foreach(a; x)
		{
			binder.visit!(typeof(a))(a, 0);
		}
		
		return new ResultSet!(T)(st, cs);
	}
}

/**
 * Main database serialization class in sendero.data.
 * 
 * If Sendero is compiled with "-version=AutoConfigDB", DBSerializer(T) will automatically
 * create and update your database tables depending on the definition of your class.
 * Note: Sendero will only add new columns, it will not modify or delete existing columns, nor will
 * it check if a column type matches the field type in your class.  This leaves the user free to
 * modify the column definitions in the database table without the serializer's interference.
 * 
 */
class DBSerializer(T)
{
	this()
	{
		log = Log.getLogger("sendero.data.DB.DBSerializer!(" ~ T.stringof ~ ")"); 
	}
	
	this(IDBConnection db)
	{
		this.db = db;
		this.tablename = TableDescriptionOf!(T).tablename;
		//auto columns = TableDescriptionOf!(T).columns;
		//auto fields = ReflectionOf!(T).fields;
		version(AutoConfigDB)
		{
			if(!db.configTable(tablename, TableDescriptionOf!(T).columns, ReflectionOf!(T).fields))
				throw new Exception("Unable to configure table " ~ tablename);
			setupInsert;
			setupUpdate;
			setupFindByID;
		}
		else
		{
			if(!db.tableExists(tablename))
				throw new Exception("Table " ~ tablename ~ " doesn't exist.  If you compile with the compiler flag \"-version=AutoConfigDB\", sendero will automatically configure your database tables.");
		}
	}
	private IDBConnection db;
	private IPreparedStatement insertStatement;
	private IPreparedStatement updateStatement;
	private IPreparedStatement findByIDStatement;
	private Logger log;
	char[] tablename;
	
	private void setupInsert()
	{
		insertStatement = db.createInsertStatement(tablename, TableDescriptionOf!(T).columns, ReflectionOf!(T).fields);
		assert(insertStatement, "No insert statement for table " ~ tablename);
	}
	
	private void setupUpdate()
	{
		updateStatement = db.createUpdateStatement(tablename, TableDescriptionOf!(T).columns, ReflectionOf!(T).fields);
		assert(updateStatement, "No update statement for table " ~ tablename);
	}
	
	private void setupFindByID()
	{
		auto pKeyIdx = TableDescriptionOf!(T).primaryKeyIndex;
		assert(pKeyIdx >= 0, "Class " ~ T.stringof ~ " has no PrimaryKey field defined");
		assert(pKeyIdx < TableDescriptionOf!(T).columns.length, "primaryKeyIndex out of bounds for class " ~ T.stringof);
		ColumnInfo[] paramCols;
		paramCols ~= TableDescriptionOf!(T).columns[pKeyIdx];
		findByIDStatement = db.createFindWhereStatement(tablename, "`id` = \?", TableDescriptionOf!(T).columns, ReflectionOf!(T).fields, paramCols);
		assert(findByIDStatement, "No find by id statement for table " ~ tablename);
	}
	
	private bool insert(T t)
	{
		debug Stdout("before setup insert").newline;
		
		if(!insertStatement) {
			setupInsert;
		}
		
		debug Stdout("begin insert").newline;
		
		auto inserter = new SetStatementBinder(insertStatement);
		ReflectionOf!(T).visitTuple(t, inserter);
		
		debug Stdout("insert set").newline;
		
		if(insertStatement.execute < 0) {
			debug Stdout("insert fail").newline;
			insertStatement.reset;
			return false;
		}
		
		debug Stdout("insert succeed").newline;
		
		auto id = insertStatement.getLastInsertID();
		if(id == 0)
			return false;
		
		debug Stdout("got id").newline;
		
		t.id.key = id;
		
		insertStatement.reset;
		
		if(TableDescriptionOf!(T).hasAssociations) {
			auto setAssoc = new SetAssociated(id, this.db);
			ReflectionOf!(T).visitTuple(t, setAssoc);
		}
		
		debug Stdout("true").newline;
		
		return true;
	}
	
	/**
	 * Saves a database object to its corresponding database table either
	 * inserting it or updating it depending on whether or not the field "PrimaryKey id"
	 * has been set.
	 */
	bool save(T t)
	{
		debug Stdout("before save").newline;
		if(t.id() == 0)
			return insert(t);

		if(!updateStatement) {
			setupUpdate;
		}
		
		auto updater = new SetStatementBinder(updateStatement);
		ReflectionOf!(T).visitTuple(t, updater);
		updateStatement.bindUInt(t.id(), updater.i);
		
		auto res = updateStatement.execute;
		updateStatement.reset;
		
		if(res < 0)
			return false;
		
		if(TableDescriptionOf!(T).hasAssociations) {
			auto setAssoc = new SetAssociated(t.id(), this.db);
			ReflectionOf!(T).visitTuple(t, setAssoc);
		}
		return true;
	}
	
	/**
	 * Deserializes an object of type T from the provided prepared statement.
	 * It is expected that the order of columns in the prepared statement
	 * correspond to those in the class's tuple.  It is safer thus to deserialize object's
	 * using the provided findByID and findWhere methods;
	 */
	T deserialize(IPreparedStatement st)
	{
		auto t = new T;
		auto deserializer = new GetStatementBinder(st, cast(void*)t, ReflectionOf!(T).fields, this.db);
		ReflectionOf!(T).visitTuple(t, deserializer);
		
		if(TableDescriptionOf!(T).hasAssociations) {
			auto getAssoc = new GetAssociated(t.id(), cast(void*)t, ReflectionOf!(T).fields, this.db);
			ReflectionOf!(T).visitTuple(t, getAssoc);
		}
		
		return t;
	}
	
	/**
	 * Finds and deserialized an object of type T with the specified id from the database.
	 */
	T findByID(ulong id)
	{
		if(!findByIDStatement) {
			setupFindByID;
		}
		
		findByIDStatement.reset;
		findByIDStatement.bindULong(id, 0);
		if(findByIDStatement.execute != SQLRESULT_ROW) {
			findByIDStatement.reset;
			return null;
		}
		auto t = deserialize(findByIDStatement);
		findByIDStatement.reset;
		return t;
	}
	
	/**
	 * Creates a finder object from the specifed where clause and the specified binding types.
	 * Note: Interface subject to change in future versions.
	 */
	Finder!(T, X) findWhere(X...)(char[] where)
	{
		//auto st = db.createStatement("SELECT * FROM `" ~ tablename ~ "` WHERE " ~ statement);
		auto visitor = new TableColumnVisitor(null);
		X x;
		uint i = 0;
		foreach(t; x)
		{
			visitor.visit(t, i);
			++i;
		}
		
		auto st = db.createFindWhereStatement(tablename, where, TableDescriptionOf!(T).columns, ReflectionOf!(T).fields, visitor.columns);
		if(!st)
			return null;
		return new Finder!(T, X)(st, this);
	}
}

package class DBHelper
{
	static char[] createInsertSql(char[] tablename, ColumnInfo[] cols, FieldInfo[] fields)
	{
		char[] q = "INSERT INTO `" ~ tablename;
		q ~= "` (";
		bool first = true;
		assert(cols.length == fields.length, tablename);
		uint n = 0;
		for(uint i = 0; i < cols.length; ++i)
		{
			if(cols[i].primaryKey) {
				assert(fields[i].name == "id");
				continue;
			}
			
			if(cols[i].skip)
				continue;
			
			if(!first) {
				q ~= ", ";
			}
			q ~= "`" ~ fields[i].name ~ "`";
			first = false;
			++n;
		}
		
		q ~= ") VALUES (";
		first = true;
		for(uint i = 0; i < n; ++i)
		{
			if(!first) {
				q ~= ", ";
			}
			q ~= "\?";
			first = false;
		}
		q ~= ")";
		return q;
	}
	
	static char[] createUpdateSql(char[] tablename, ColumnInfo[] cols, FieldInfo[] fields)
	{		
		char[] q = "UPDATE `" ~ tablename ~ "` SET ";
		bool first = true;
		assert(cols.length == fields.length, tablename);
		for(uint i = 0; i < cols.length; ++i)
		{
			if(cols[i].primaryKey)
				continue;
			
			if(cols[i].skip)
				continue;
			
			if(!first)
				q ~= ", ";
			
			q ~= "`" ~ fields[i].name ~ "` = \?";
			
			first = false;
		}
		
		q ~= " WHERE id = \?";
		
		return q;
	}
	
	static char[] createFindWhereStatement(char[] tablename, char[] where, ColumnInfo[] cols, FieldInfo[] fields)
	{
		char[] q = "SELECT ";
		bool first = true;
		assert(cols.length == fields.length, tablename);
		for(uint i = 0; i < cols.length; ++i)
		{			
			if(cols[i].skip)
				continue;
			
			if(!first)
				q ~= ", ";
			
			q ~= "`" ~ fields[i].name ~ "`";
			
			first = false;
		}
		
		q ~= " FROM `"~ tablename ~ "` WHERE " ~ where;
		
		return q;
	}
}

version(Unittest)
{
	import sendero.data.Associations;
	import Integer = tango.text.convert.Integer;
	
	class TestModel
	{
		PrimaryKey id;
		void[] blob;
		char[] txt;
	}
}

unittest
{
	assert(TableDescriptionOf!(TestModel).columns[0].type == ColT.UInt, Integer.toUtf8(TableDescriptionOf!(TestModel).columns[0].type));
	assert(TableDescriptionOf!(TestModel).columns[1].type == ColT.Blob, Integer.toUtf8(TableDescriptionOf!(TestModel).columns[1].type));
	assert(TableDescriptionOf!(TestModel).columns[2].type == ColT.VarChar, Integer.toUtf8(TableDescriptionOf!(TestModel).columns[2].type));
}