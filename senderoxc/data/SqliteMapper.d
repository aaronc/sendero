module senderoxc.data.SqliteMapper;

import senderoxc.data.Mapper;

import dbi.all;
import dbi.sqlite.SqliteDatabase;

class SqliteMapper : Mapper
{
	static this()
	{
		Mapper.registerMapperClass("Sqlite", &SqliteMapper.create);
	}
	
	static SqliteMapper create()
	{
		return new MysqlMapper;
	}
	
	void writeDBAlias(IPrint wr)
	{
		wr.fln("alias DefaultSqliteProvider db;");
	}
}