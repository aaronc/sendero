module senderoxc.data.mapper.Delete;

import senderoxc.data.mapper.IMapper;

debug import tango.io.Stdout;

class DeleteResponder : IMapperResponder
{
	this(IMapper m)
	{
		this.mapper = m;
		
		if(mapper.schema.getPrimaryKeyCols.length)
			mapper.addMethod(new FunctionDeclaration("destroy", "bool"));
	}
	
	private IMapper mapper;
	
	
	void doWrite(IPrint wr)
	{
		if(!mapper.schema.getPrimaryKeyCols.length)
			return;
		
		wr("private static char[] deleteSql;\n");
		
		wr("public bool destroy()\n");
		wr("{\n");
		
		wr.indent;
		wr.fln("static if(is(typeof(this.beforeDestroy))) if(!this.beforeDestroy) return false;");
		wr.fln("auto db = getDb();");
		wr.fln("if(!deleteSql.length) deleteSql = db.sqlGen.makeDeleteSql({}, [{}]);",
			DQuote(mapper.schema.tablename), makeQuotedList(mapper.schema.getPrimaryKeyCols()));
		wr.fln("db.query(deleteSql,{});",makeList(mapper.getPrimaryKeyFields));
		
		wr.fln("static if(is(typeof(this.afterDestroy))) this.afterDestroy;");
		
		//wr.fln("st.execute({});", );
		wr.fln("return (db.affectedRows == 1) ? true : false;");
		wr.dedent;
		wr("}\n");
		wr("\n");
	}
	
	final void write(IPrint wr)
	in
	{
		assert(wr); assert(mapper);	assert(mapper.schema);
	}
	body
	{
		if(mapper.obj.parent !is null && mapper.obj.inheritance == InheritanceType.SingleTable)
			return;
		
		doWrite(wr);
	}
}