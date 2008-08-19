module senderoxc.data.mapper.mysql.Delete;

import senderoxc.data.mapper.Delete;
import senderoxc.data.mapper.mysql.IMysqlMapper;

class MysqlDeleteResponder : DeleteResponder
{
	this(IMysqlMapper m)
	{
		super(m);
		this.mapper = m;
	}
	
	private IMysqlMapper mapper;
	
	void write(IPrint wr)
	{
		wr("public void destroy()\n");
		wr("{\n");
		wr.indent;
		wr.fln(`const char[] deleteSql = {};`,
			DQuoteString(mapper.db.sqlGen.makeDeleteSql(mapper.schema.tablename, mapper.schema.getPrimaryKeyCols)));
		wr("scope st = db.prepare(deleteSql);\n");
		wr.fln("st.execute({});", makeList(mapper.getPrimaryKeyFields));
		wr.dedent;
		wr("}\n");
		wr("\n");
	}
}