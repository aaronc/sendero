module senderoxc.data.Schema;

import dbi.Database;

debug import tango.io.Stdout;

class Schema
{
	static Schema[char[]] schemas;
	
	private this(char[] tablename)
	{
		this.tablename = tablename;
	}
	
	static Schema create(char[] tablename)
	{
		auto pSchema = tablename in schemas;
		if(pSchema) throw new Exception("Schema for table " ~ tablename ~ " already exists");
		
		auto schema = new Schema(tablename);
		schemas[tablename] = schema;
		return schema;
	}
	
	char[] tablename;
	ColumnInfo[char[]] columns;
	
	void addColumn(ColumnInfo i)
	{
		auto pCol = i.name in columns;
		if(pCol) throw new Exception("Column " ~ i.name ~ " already exists in schema for table " ~ tablename);
		
		columns[i.name] = i;
	}
	
	static ColumnInfo prepColumnInfo(FieldType type)
	{
		ColumnInfo col;
		col.type = type.bindType;
		col.limit = type.limit;
		return col;
	}
	
	struct FieldType
	{
		char[] type;
		char[] DType;
		BindType bindType;
		uint limit;
	}
	
	const static FieldType[] FieldTypes =
		[
		 FieldType("Bool","bool", BindType.Bool),
		 FieldType("UByte","ubyte", BindType.UByte),
		 FieldType("Byte","byte", BindType.Byte),
		 FieldType("UShort","ushort", BindType.UShort),
		 FieldType("Short","short", BindType.Short),
		 FieldType("UInt","uint", BindType.UInt),
		 FieldType("Int","int", BindType.Int),
		 FieldType("ULong","ulong", BindType.ULong),
		 FieldType("Long","long", BindType.Long),
		 FieldType("Float","float", BindType.Float),
		 FieldType("Double","double", BindType.Double),
		 FieldType("String","char[]", BindType.String, 255),
		 FieldType("Text","char[]", BindType.String, ushort.max - 1),
		 FieldType("Binary","ubyte[]", BindType.Binary, 255),
		 FieldType("Blob","ubyte[]", BindType.Binary, ushort.max - 1),
		 FieldType("DateTime","DateTime", BindType.DateTime),
		 FieldType("Time","Time", BindType.Time),
		 //FieldType("Date","Date", BindType.Date),
		 //FieldType("TimeOfDay","TimeOfDay", BindType.Date)
		 ];
	
	static void commit(Database db)
	{
		foreach(tname, schema; schemas)
		{
			if(db.hasTable(tname)) {
				auto metadata = db.getTableInfo(tname);
				
				ColumnInfo[char[]] schemaCopy;
				foreach(name, col; schema.columns) schemaCopy[name] = col;
				
				foreach(col; metadata)
				{
					if(col.name in schemaCopy) schemaCopy.remove(col.name);
				}
				
				ColumnInfo[] alterCols;
				foreach(name, col; schemaCopy) alterCols ~= col;
				
				if(alterCols.length) {
					Stdout.formatln("Altering table {}, adding columns: ", tname);
					Stdout("\t");
					foreach(col; alterCols) Stdout(col.name)(" ");
					Stdout.newline;
					
					foreach(col; alterCols)
					{
						auto addSql = db.sqlGen.makeAddColumnSql(tname, col);
						Stdout.formatln("\tAdding column {} to table {}", col.name, tname);
						db.execute(addSql);
					}
				}
				else Stdout.formatln("Table {} is up-to-date", tname);
			}
			else {
				Stdout.formatln("Creating table {} with columns: ", tname);
				Stdout("\t");
				foreach(col; schema.columns) Stdout(col.name)(" ");
				Stdout.newline;
				
				ColumnInfo[] cols;
				
				foreach(name, col; schema.columns) cols ~= col;
				auto createSql = db.sqlGen.makeCreateSql(tname, cols);
				db.execute(createSql);
			}
		}
	}
}


//import sendero.db.DBProvider;
//import tango.core.Signal;
/+
class SchemaBuilder
{
	Signal!() beforeCreateTable;
	Signal!() afterCreateTable;
	
	void create()
	{
		beforeCreateTable();
		
		afterCreateTable();
	}
}

+/