module senderoxc.data.Mapper;

import senderoxc.data.mapper.IMapper;

import sendero.core.Config;
import dbi.all;

import senderoxc.data.mapper.Delete;

class Mapper : IMapper
{
	static Mapper create(char[] className, Schema schema, IInterfaceWriter iface)
	{
		auto db = getDatabaseForURL(SenderoConfig().dbUrl);
		auto pCtr = db.type in mapperCtrs;
		if(pCtr !is null) return (*pCtr)(className, schema, iface);
		else return new Mapper(className, schema, iface);
	}
	
	protected this(char[] className, Schema schema, IInterfaceWriter iface)
	{
		this.classname_ = className;
		
		assert(schema);
		assert(iface);
		
		this.schema_ = schema;
		this.iface = iface;
	}
	
	private const char[] classname_;
	
	char[] classname() { return classname_; }
	
	public Schema schema() { return schema_; }
	protected Schema schema_;
	private IInterfaceWriter iface;
	private IMapperResponder[] responders;
	
	alias Mapper function(char[] className, Schema schema, IInterfaceWriter iface) MapperCtr;
	
	protected static void registerMapperClass(char[] type, MapperCtr create)
	{
		mapperCtrs[type] = create;
	}
	
	private static MapperCtr[char[]] mapperCtrs;
	
	void writeDBAlias(IPrint wr)
	{
		wr.fln("alias DefaultDatabaseProvider db;");
	}
	
	IMapperResponder getDeleteResponder()
	{
		return new DeleteResponder(this);
	}
	
	final void init()
	{
		responders ~= getDeleteResponder;
	}
	
	final void write(IPrint wr)
	{
		writeDBAlias(wr);
		
		foreach(resp; responders)
			resp.write(wr);
	}
	
	final char[][] getPrimaryKeyFields()
	{
		return schema.getPrimaryKeyCols();
	}
	
	final void addInterface(char[] interfaceName, char[][] imports = null)
	{
		iface.addInterface(interfaceName, imports);
	}
	
	final void addMethod(FunctionDeclaration decl)
	{
		iface.addMethod(decl);
	}
}
