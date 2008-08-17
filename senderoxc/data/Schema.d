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
	
	static char[] getDType(char[] type)
	{
		/+switch(decoratorType)
		{
		case "Bool": return "bool";
		case "UByte": return "ubyte";
		case "Byte": return "byte";
		case "UShort": return "short";
		case "Short": return "short";
		case "UInt": return "uint";
		case "Int": return "int";
		case "ULong": return "ulong";
		case "Long": return "long";
		case "Float": return "float";
		case "Double": return "double";
		case "String": return "char[]";
		case "Text": return "char[]";
		case "Binary": return "ubyte[]";
		case "Blob": return "ubyte[]";
		case "DateTime": return "DateTime";
		case "Time": return "Time";
		default: assert(false, "Unsupport field decorator type " ~ decoratorType);
		}+/
		
		auto pType = type in FieldTypes2;
		assert(pType, "Unsupported field type " ~ type);
		return pType.DType;
	}
	
	static ColumnInfo prepColumnInfo(char[] type)
	{
		ColumnInfo col;
		auto pType = type in FieldTypes2;
		assert(pType, "Unsupported field type " ~ type);
		col.type = pType.bindType;
		col.limit = pType.limit;
		return col;
		/+switch(fieldType)
		{
		case "Bool": col.type = BindType.Bool; break;
		case "UByte": col.type = BindType.UByte; break;
		case "Byte": col.type = BindType.Byte; break;
		case "UShort": col.type = BindType.UShort; break;
		case "Short": col.type = BindType.Short; break;
		case "UInt": col.type = BindType.UInt; break;
		case "Int": col.type = BindType.Int; break;
		case "ULong": col.type = BindType.ULong; break;
		case "Long": col.type = BindType.Long; break;
		case "Float": col.type = BindType.Float; break;
		case "Double": col.type = BindType.Double; break;
		case "String": col.type = BindType.String; col.limit = 255; break;
		case "Text": col.type = BindType.String; col.limit = ushort.max - 1; break;
		case "Binary": col.type = BindType.Binary; col.limit = 255; break;
		case "Blob": col.type = BindType.Binary; col.limit = ushort.max - 1; break;
		case "DateTime": col.type = BindType.DateTime; break;			
		case "Time": col.type = BindType.Time; break;
		default: assert(false, "Unsupport field type " ~ fieldType);
		}
		return col;+/
	}
	
	static this()
	{
		foreach(f; fields) FieldTypes2[f.type] = f;
	}
	
	static FieldType[char[]] FieldTypes2;
	
	struct FieldType
	{
		char[] type;
		char[] DType;
		BindType bindType;
		uint limit;
	}
	
	const static FieldType[] fields =
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
	
	
	deprecated const static char[][] FieldTypes = 
		[
		 "Bool",
		 "UByte",
		 "Byte",
		 "UShort",
		 "Short",
		 "UInt",
		 "Int",
		 "ULong",
		 "Long",
		 "Float",
		 "Double",
		 //"real",
		 //"text",
		 "String",
		 "Text",
		 "Binary",
		 "Blob",
		 "DateTime",
		 "Time",
		 //"Date",
		 //"TimeOfDay"
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