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
	
	static ColumnInfo prepColumnInfo(char[] fieldType)
	{
		ColumnInfo col;
		switch(fieldType)
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
		case "Blob": col.type = BindType.Binary; col.limit = 255; break;
		case "DateTime": col.type = BindType.DateTime; break;			
		case "Time": col.type = BindType.Time; break;
		default: assert(false, "Unsupport field type " ~ fieldType);
		}
		return col;
	}
	
	const static char[][] FieldTypes = 
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