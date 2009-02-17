module senderoxc.data.mapper.mysql.IMysqlMapper;

public import senderoxc.data.mapper.IMapper;

public import dbi.DBI, dbi.mysql.Mysql;

interface IMysqlMapper : IMapper
{
	Mysql db();
}