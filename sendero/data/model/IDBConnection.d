module sendero.data.model.IDBConnection;

public import tango.core.Type;
public import tango.util.time.Date;
public import tango.util.time.DateTime;

public import sendero.util.FieldInfo;
public import sendero.util.ColumnInfo;

interface IDBConnection
{
	IPreparedStatement createStatement(char[] statement);
	bool tableExists(char[] tablename);
	bool configTable(char[] tablename, ColumnInfo[] cols, FieldInfo[] fields);
	IPreparedStatement createInsertStatement(char[] tablename, ColumnInfo[] cols, FieldInfo[] fields);
	IPreparedStatement createUpdateStatement(char[] tablename, ColumnInfo[] cols, FieldInfo[] fields);
	IPreparedStatement createFindWhereStatement(char[] tablename, char[] where, ColumnInfo[] cols, FieldInfo[] fields);
	//IPreparedStatement createFindByIDStatement(char[] tablename);
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
	bool bindDateTime(DateTime dt, uint index);
		
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
	bool getDateTime(inout DateTime dt, uint index);
}