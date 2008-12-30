module senderoxc.data.mapper.Save;

import senderoxc.data.mapper.IMapper;

class SaveResponder(MapperT = IMapper) : IMapperResponder
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
		wr.fln("bool save()");
		wr("{").nl;
		wr.indent;
		
		wr.fln("auto db = getDb;");
		wr.fln("char[][{}] fields;",mapper.mappings.length + 1);
		wr.fln("BindType[{}] bindTypes;",mapper.mappings.length + 1);
		wr.fln("void*[{}] bindPtrs;",mapper.mappings.length + 1);
		wr.fln("BindInfo bindInfo;");
		wr.fln("uint idx = 0;");

		foreach(field; mapper.mappings)
		{
			wr.fln("if({}) { fields[idx] = {}; ++idx;}", field.isModifiedExpr, DQuote(field.colname));
		}
		
		wr.fln("if(id_) {{ fields[idx] = \"id\"; ++idx; }");
		
		wr.fln("bindInfo.types = setBindTypes(fields[0..idx], bindTypes);");
		wr.fln("bindInfo.ptrs = setBindPtrs(field[0..idx], bindPtrs);");
		
		wr.fln("if(id_) {{");
		wr.indent;
		
		
		wr.fln(`auto res = db.update({}, fields[0..idx], "WHERE id = ?", bindInfo);`,
				DQuote(mapper.schema.tablename));
		
		wr.fln(`if(db.affectedRows == 1) return true; else return false;`);
		
		wr.dedent;
		wr.fln("}}");
		
		wr.fln("else {{");
		wr.indent;
		
		wr.fln("auto res = db.insert({}, fields[0..idx], bindInfo);",
			DQuote(mapper.schema.tablename));
		
		wr.fln("id_ = db.lastInsertID;");
			
		wr.fln(`if(id_) return true; else return false;`);
		
		wr.dedent;
		wr.fln("}}");
		
		
		wr.dedent;
		wr("}").nl;
		wr.nl;
	}
}