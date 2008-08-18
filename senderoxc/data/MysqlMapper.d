module senderoxc.data.MysqlMapper;

import senderoxc.data.Mapper;
import senderoxc.data.mapper.mysql.IMysqlMapper;

import senderoxc.data.mapper.mysql.Delete;

import sendero.core.Config;

class MysqlMapper : Mapper, IMysqlMapper
{
	static this()
	{
		Mapper.registerMapperClass("Mysql", &MysqlMapper.create);
	}
	
	static Mapper create(char[] className, Schema schema, IInterfaceWriter iface)
	{
		return new MysqlMapper(className, schema, iface);
	}
	
	protected this(char[] className, Schema schema, IInterfaceWriter iface)
	{
		super(className, schema, iface);
		db_ = cast(MysqlDatabase)getDatabaseForURL(SenderoConfig().dbUrl);
		assert(db_, "Database is not of type Mysql");
	}
	
	MysqlDatabase db() { return db_; }
	private MysqlDatabase db_;
	
	void writeDBAlias(IPrint wr)
	{
		wr.fln("alias DefaultMysqlProvider db;");
	}
	
	IMapperResponder getDeleteResponder()
	{
		return new MysqlDeleteResponder(this);
	}
}