module sendero.data.DB;

public import tango.core.Type;
public import tango.util.time.Date;
public import tango.util.time.DateTime;

import sendero.util.Reflection;

debug import tango.io.Stdout;

package const int SQLRESULT_FAIL = -1;
package const int SQLRESULT_SUCCESS = 0;
package const int SQLRESULT_ROW = 1;

interface IDBConnection
{
	IPreparedStatement createStatement(char[] statement);
	bool tableExists(char[] tablename);
	bool configTable(char[] tablename, ColumnInfo[] cols, FieldInfo[] fields);
	IPreparedStatement createInsertStatement(char[] tablename, ColumnInfo[] cols, FieldInfo[] fields);
	IPreparedStatement createUpdateStatement(char[] tablename, ColumnInfo[] cols, FieldInfo[] fields);
	IPreparedStatement createFindByIDStatement(char[] tablename);
	IDBSerializer getDBSerializer(char[] mangledname);
	void storeDBSerializer(IDBSerializer cs);
}

interface IPreparedStatement
{
	int execute();
	void reset();
	ulong getLastInsertID();
	
	bool bindShort(short x, uint index);
	bool bindUShort(ushort x, uint index);
	bool bindInt(int x, uint index);
	bool bindUInt(uint x, uint index);
	bool bindLong(long x, uint index);
	bool bindULong(ulong x, uint index);
	bool bindBool(bool x, uint index);
	bool bindFloat(float x, uint index);
	bool bindDouble(double x, uint index);
	bool bindString(char[] x, uint index);
	bool bindBlob(void[] x, uint index);
	//bool bindDate(Date dt, uint index);
	//bool bindTime(Time dt, uint index);
	//bool bindDateTime(DateTime dt, uint index);
		
	bool getShort(inout short x, uint index);
	bool getUShort(inout ushort x, uint index);
	bool getInt(inout int x, uint index);
	bool getUInt(inout uint x, uint index);
	bool getLong(inout long x, uint index);
	bool getULong(inout ulong x, uint index);
	bool getBool(inout bool x, uint index);
	bool getFloat(inout float x, uint index);
	bool getDouble(inout double x, uint index);
	bool getString(inout char[] x, uint index);
	bool getBlob(inout void[] x, uint index);
	//bool getDate(inout Date dt, uint index);
	//bool getTime(inout Time dt, uint index);
	//bool getDateTime(inout DateTime dt, uint index);
}

struct PrimaryKey
{
	private uint key = 0;
	uint opCall()
	{
		return key;
	}
}

enum ColT { Bool, Byte, Short, Int, Long, UByte, UShort, UInt, ULong, Float, Double, VarChar, Text, LongText, Blob, LongBlob, Date, DateTime, TimeStamp, HasOne, HasMany, HABTM, Variant, Object};

class ColumnInfo
{
	ColT type;
	bool notNull;
	bool unique;
	bool primaryKey;
}

static class TableColumnVisitor
{
	this(char[] classname)
	{
		this.classname = classname;
	}
	
	char[] classname;
	ColumnInfo[] columns;
	
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
		else static if(is(X == PrimaryKey)) {
			info.primaryKey = true;
			info.type = ColT.UInt;
		}
		else static if(X.stringof[0 .. 6] == "HasOne") {
			info.type = ColT.HasOne;
		}
		else static if(X.stringof[0 .. 5] == "HABTM") {
			info.type = ColT.HABTM;
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
		tablename =  T.stringof;
		auto visitor = new TableColumnVisitor(T.stringof);
		auto t = new T;
		ReflectionOf!(T).visitTuple(t, visitor);
		columns = visitor.columns;
	}
	
	static const char[] tablename;
	static const ColumnInfo[] columns;
}

class SetStatementBinder
{
	this(IPreparedStatement st)
	{
		this.st = st;
	}
	
	IPreparedStatement st;
	uint i = 1;
	
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
		else static if(is(X == PrimaryKey)) {
			return;
		}
		else static if(X.stringof[0 .. 6] == "HasOne") {
			if(x.id) st.bindULong(x.id, i);
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
		else static if(is(X == PrimaryKey)) {
			uint id;
			st.getUInt(id, i);
			x.key = id;
		}
		else static if(X.stringof[0 .. 6] == "HasOne") {
			ulong id;
			st.getULong(id, i);
			x.id = id;
			auto cs = db.getDBSerializer(x.type.mangleof);
			if(cs) {
				auto tCS = cast(DBSerializer!(x.type))cs;
				if(tCS) {
					x.db = tCS;
				}
				else {
					tCS = new DBSerializer!(x.type)(db);
					db.storeDBSerializer(tCS);
					x.db = tCS;
				}
			}
			else {
				auto tCS = new DBSerializer!(x.type)(db);
				db.storeDBSerializer(tCS);
				x.db = tCS;
			}
		}
		else assert(false, "Unhandled bind type");
		*cast(X*)(start + fields[index].offset) = x;
		
		++i;
	}
}

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
	Database.Serializer!(T) cs;
	
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

class Finder(T, X...)
{
	private this(IPreparedStatement st, DBSerializer!(T) cs, X x = null)
	{
		this.st = st;
		this.cs = cs;
		this.x_ = x;
	}
	IPreparedStatement st;
	Database.Serializer!(T) cs;
	X x_;
	
	ResultSet!(T) find(X x = null)
	{
		if(!x) {
			if(!x_)
				return null;
			x = x_;
		}
		
		st.reset;
		auto binder = new SetStatementBinder(st);
			
		foreach(a; x)
		{
			binder.visit(a, 0);
		}
		
		return new ResultSet!(T)(st, cs);
	}
}

interface IDBSerializer
{
	char[] mangledname();
}

class DBSerializer(T) : IDBSerializer
{
	this(IDBConnection db)
	{
		this.db = db;
		this.tablename = TableDescriptionOf!(T).tablename;
		version(AutoConfigDB)
		{
			if(!db.configTable(tablename, TableDescriptionOf!(T).columns, ReflectionOf!(T).fields))
				throw new Exception("Unable to configure table " ~ tablename);
		}
		else
		{
			if(!db.tableExists(tablename))
				throw new Exception("Table " ~ tablename ~ " doesn't exist.  If you compile with the compiler flag \"-version=AutoConfigDB\", sendero will automatically configure your database tables.");
		}
		
		insertStatement = db.createInsertStatement(tablename, TableDescriptionOf!(T).columns, ReflectionOf!(T).fields);
		assert(insertStatement, "No insert statement for table " ~ tablename);
		updateStatement = db.createUpdateStatement(tablename, TableDescriptionOf!(T).columns, ReflectionOf!(T).fields);
		assert(updateStatement, "No update statement for table " ~ tablename);
		findByIDStatement = db.createFindByIDStatement(tablename);
		assert(findByIDStatement, "No find by id statement for table " ~ tablename);
	}
	private IDBConnection db;
	private IPreparedStatement insertStatement;
	private IPreparedStatement updateStatement;
	private IPreparedStatement findByIDStatement;
	char[] tablename;
	char[] mangledname() {return T.mangleof;}
	
	private bool insert(T t)
	{
		auto inserter = new SetStatementBinder(insertStatement);
		ReflectionOf!(T).visitTuple(t, inserter);
		
		if(insertStatement.execute < 0) {
			insertStatement.reset;
			return false;
		}
		
		auto id = insertStatement.getLastInsertID();
		if(id == 0)
			return false;
		
		t.id.key = id;
		
		insertStatement.reset;
		return true;
	}
	
	bool save(T t)
	{
		if(t.id() == 0)
			return insert(t);
		
		auto updater = new SetStatementBinder(updateStatement);
		ReflectionOf!(T).visitTuple(t, updater);
		updateStatement.bindUInt(t.id(), updater.i);
		
		auto res = updateStatement.execute;
		updateStatement.reset;
		return res >= 0 ? true : false;
	}
	
	T deserialize(IPreparedStatement st)
	{
		auto t = new T;
		auto deserializer = new GetStatementBinder(st, cast(void*)t, ReflectionOf!(T).fields, this.db);
		ReflectionOf!(T).visitTuple(t, deserializer);
		return t;
	}
	
	T findByID(ulong id)
	{
		findByIDStatement.reset;
		findByIDStatement.bindULong(id, 1);
		if(findByIDStatement.execute != SQLRESULT_ROW) {
			findByIDStatement.reset;
			return null;
		}
		auto t = deserialize(findByIDStatement);
		findByIDStatement.reset;
		return t;
	}
	
	ResultSet!(T) findWhere(X...)(char[] statement, X value = null)
	{
		auto st = db.createStatement("SELECT * FROM " ~ cs.desc.tablename ~ " WHERE " ~ statement);
		if(!st)
			return null;
		return new Finder!(T, X)(st, this, value);
	}
}

package class DBHelper
{
	static char[] createInsertSql(char[] tablename, ColumnInfo[] cols, FieldInfo[] fields)
	{
		char[] q = "INSERT INTO " ~ tablename;
		q ~= "(";
		bool first = true;
		assert(cols.length == fields.length, tablename);
		uint n = 0;
		for(uint i = 0; i < cols.length; ++i)
		{
			if(cols[i].primaryKey) {
				assert(fields[i].name == "id");
				continue;
			}
			
			if(!first) {
				q ~= ", ";
			}
			q ~= fields[i].name;
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
		q ~= ");";
		return q;
	}
	
	static char[] createUpdateSql(char[] tablename, ColumnInfo[] cols, FieldInfo[] fields)
	{		
		char[] q = "UPDATE " ~ tablename ~ " SET ";
		bool first = true;
		assert(cols.length == fields.length, tablename);
		for(uint i = 0; i < cols.length; ++i)
		{
			if(cols[i].primaryKey)
				continue;
			
			if(!first)
				q ~= ", ";
			
			q ~= fields[i].name ~ " = \?";
			
			first = false;
		}
		
		q ~= " WHERE id = \?";
		
		return q;
	}
	
	static char[] createFindByIDSql(char[] tablename)
	{
		char[] q = "SELECT * FROM " ~ tablename ~ " WHERE id = \?";
		return q;
	}
}

version(Unittest)
{
	import Integer = tango.text.convert.Integer;
	
	class TestBlob
	{
		PrimaryKey id;
		void[] blob;
		char[] txt;
	}
	
	class TestModel
	{
		PrimaryKey id;
		int x = 5;
		int y = 7;
		int z = 9;
		double d;
		double e;
		int f;
	}
}

unittest
{
	assert(TableDescriptionOf!(TestBlob).columns[0].type == ColT.UInt, Integer.toUtf8(TableDescriptionOf!(TestBlob).columns[0].type));
	assert(TableDescriptionOf!(TestBlob).columns[1].type == ColT.Blob, Integer.toUtf8(TableDescriptionOf!(TestBlob).columns[1].type));
	assert(TableDescriptionOf!(TestBlob).columns[2].type == ColT.VarChar, Integer.toUtf8(TableDescriptionOf!(TestBlob).columns[2].type));
}