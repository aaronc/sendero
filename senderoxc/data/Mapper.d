module senderoxc.data.Mapper;

import senderoxc.data.mapper.IMapper;
import senderoxc.data.IDataResponder;

import sendero.core.Config;
import dbi.DBI;

import senderoxc.data.mapper.Delete;
import senderoxc.data.mapper.Save;

class Mapper : IMapper
{
	static Mapper create(char[] className, IDataResponder res)
	{
		auto db = getDatabaseForURL(SenderoConfig().dbUrl);
		auto pCtr = db.type in mapperCtrs;
		if(pCtr !is null) return (*pCtr)(className, res);
		else return new Mapper(className, res);
	}
	
	protected this(char[] className, IDataResponder res)
	{
		assert(res);
		assert(res.schema);
		assert(res.obj);
		
		this.classname_ = className;
		this.schema_ = res.schema;
		this.obj_ = res.obj;
		this.iface_ = res;
	}
	
	alias Mapper function(char[] className, IDataResponder res) MapperCtr;
	
	protected static void registerMapperClass(char[] type, MapperCtr create)
	{
		mapperCtrs[type] = create;
	}
	
	private static MapperCtr[char[]] mapperCtrs;
	
	
	char[] classname() { return classname_; }
	private const char[] classname_;
	
	public Schema schema() { return schema_; }
	private Schema schema_;
	
	public IObjectResponder obj() { return obj_; }
	private IObjectResponder obj_;
	
	private IInterfaceWriter iface_;
	private IMapperResponder[] responders;
	
	void writeDBAlias(IPrint wr)
	{
		wr.fln("alias DefaultDatabaseProvider db;");
	}
	
	IMapperResponder getDeleteResponder()
	{
		return new DeleteResponder(this);
	}
	
	IMapperResponder getSaveResponder()
	{
		return new SaveResponder!()(this);
	}
	
	final void init()
	{
		void add(IMapperResponder responder)
		{
			if(responder !is null)
				responders ~= responder;
		}
		
		add(getDeleteResponder);
		add(getSaveResponder);
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
		iface_.addInterface(interfaceName, imports);
	}
	
	final void addMethod(FunctionDeclaration decl)
	{
		iface_.addMethod(decl);
	}
	
	final void addMapping(IMapping mapping)
	{
		mappings_ ~= mapping;
	}
	
	final IMapping[] mappings()
	{
		return mappings_;
	}
	
	IMapping[] mappings_;
}
