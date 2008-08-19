module senderoxc.data.mapper.Delete;

import senderoxc.data.mapper.IMapper;

debug import tango.io.Stdout;

class DeleteResponder : IMapperResponder
{
	this(IMapper m)
	{
		m.addMethod(new FunctionDeclaration("destroy", "void"));
		this.mapper = m;
	}
	
	private IMapper mapper;
	
	
	void write(IPrint wr)
	in
	{
		assert(wr); assert(mapper);	assert(mapper.schema);
	}
	body
	{
		wr("private static char[] deleteSql;\n");
		
		wr("public void destroy()\n");
		wr("{\n");
		wr.indent;
		wr.fln("if(!deleteSql.length) deleteSql = db.sqlGen.makeDeleteSql({}, [{}]);",
			DQuote(mapper.schema.tablename), makeQuotedList(mapper.schema.getPrimaryKeyCols()));
		wr("scope st = db.prepare(deleteSql);\n");
		wr.fln("st.execute({});", makeList(mapper.getPrimaryKeyFields));
		wr.dedent;
		wr("}\n");
		wr("\n");
	}
}