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
		
		wr.fln("if(id_) {{");
		wr.indent;
		wr.fln("char[][] fields");

		foreach(field; mapper.obj.fields)
		{
			if(field.hasSetter)
				wr.fln("if({}) fields ~= {};", field.isModifiedExpr, DQuote(field.colname));
		}
		
		wr.fln("auto sql = db.sqlGen.makeInsertSql({}, fields);",
				DQuote(mapper.schema.tablename));
		
		foreach(field; mapper.obj.fields)
		{
			if(field.hasSetter)
				wr.fln("if({}) ;", field.isModifiedExpr);
		}
		
		wr.dedent;
		wr.fln("}}");
		
		wr.fln("else {{");
		wr.indent;
		foreach(field; mapper.obj.fields)
		{
			
		}
		wr.dedent;
		wr.fln("}}");
		wr.dedent;
		wr("}").nl;
		wr.nl;
	}
}