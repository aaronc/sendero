module senderoxc.data.mapper.mysql.Save;

import senderoxc.data.mapper.mysql.IMysqlMapper;

class MysqlSaveResponder(MapperT = IMapper) : IMapperResponder
{
	this(MapperT m)
	{
		m.addMethod(new FunctionDeclaration("save", "bool"));
		this.mapper = m;
	}
	protected MapperT mapper;
	
	void write(IPrint wr)
	in
	{
		assert(mapper);
		assert(mapper.schema);
		assert(mapper.obj);
		assert(wr);
	}
	body
	{
		auto primKey = mapper.schema.getPrimaryKeyCols;
		//assert(primKey.length == 1, "Only single column primary keys supported so far - Class: " ~ mapper.obj.classname);
		if(primKey.length != 1) return;
		
		if(mapper.obj.inheritance == InheritanceType.SingleTable) {
			wr.fln(`protected char[] classname() {{ return "{}";}`, mapper.obj.classname);
		}
		
		wr.fln("protected void writeSerialization(void delegate(char[]) write)");
		wr("{").nl;
		wr.indent;
		
		if(mapper.obj.parent !is null)
			wr.fln("super.writeSerialization(write);");
		
		foreach(mapping; mapper.mappings)
		{
			wr.f("if({}) {{ {}", mapping.isModifiedExpr, writeWriteExpr(`"` ~ mapping.colname ~ ` = "`));
			wr.f(writeSerializeFieldExpr(mapping));
			wr("}\n");
		}

		wr.dedent;
		wr("}").nl;
		wr.nl;
		
		if(mapper.obj.parent !is null && mapper.obj.inheritance == InheritanceType.SingleTable)
			return;
		
		wr.fln("bool save()");
		wr("{").nl;
		wr.indent;
		
		wr("if(id_) ");
		wr(writeWriteExpr(`"INSERT INTO "`))(";\n");
		wr("else ");
		wr(writeWriteExpr(`"UPDATE "`))(";\n");
		wr.f(writeWriteExpr(`"{} SET "`), writeTableQuoteExpr(mapper.schema.tablename));
		wr(";\n");

		wr.fln("writeSerialization(write);");
		
		if(mapper.obj.inheritance == InheritanceType.SingleTable) {
			wr("if(!id_) ")(writeWriteExpr(`"class = " ~ classname ~ ","`)).nl;
		}
		
		wr(writeWriteExpr("\" WHERE `" ~ primKey[0] ~ "` = \" ~ Integer.toString(id_)"))(";\n");

		wr.dedent;
		wr("}").nl;
		wr.nl;
	}
	
	char[] writeSerializeFieldExpr(IMapping field)
	{
		switch(field.dtype)
		{
		case "ubyte":
		case "byte":
		case "ushort":
		case "short":
		case "uint":
		case "int":
		case "ulong":
		case "long":
		case "bool":
			break;
			return writeWriteExpr("Integer.toString(\"" ~ field.fieldAccessor ~ "\")");
		case "float":
		case "double":
			return writeWriteExpr("Float.toString(\"" ~ field.fieldAccessor ~ "\")");
			break;
		case "char[]":
		case "ubyte[]":
		case "void[]":
			char[] res = `temp = writer.getWriteBuffer(` ~ field.fieldAccessor ~ `.length * 2);`;
			res ~= `tempLen = mysql_real_escape_string(db.database.handle,temp.ptr,` 
				~ field.fieldAccessor ~ `.ptr,` ~ field.fieldAccessor ~ `.length);`;
			res ~= writeWriteExpr(`temp[0..tempLen]`);
			return res;
		case "Time":
		case "Date":
		case "DateTime":
			//assert(false);
			return "NULL";
		default:
			assert(false);
			break;
		}
	}
	
	char[] writeWriteExpr(char[] str)
	{
		return `write(` ~ str ~ `);`;
	}
	
	char[] writeTableQuoteExpr(char[] str)
	{
		return "`" ~ str ~ "`";
	}
}