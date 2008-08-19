module senderoxc.data.Mapper;

import senderoxc.data.mapper.IMapper;
import senderoxc.data.IDataResponder;

import sendero.core.Config;
import dbi.all;

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
		this.classname_ = className;
		
		assert(res);
		assert(res.schema);
		
		this.schema_ = res.schema;
		this.iface = res;
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
	
	private IInterfaceWriter iface;
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
		responders ~= getDeleteResponder;
		responders ~= getSaveResponder;
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
