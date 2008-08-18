module senderoxc.data.mapper.mysql.IMysqlMapper;

public import senderoxc.data.mapper.IMapper;

public import dbi.all, dbi.mysql.MysqlDatabase;

interface IMysqlMapper : IMapper
{
	MysqlDatabase db();
}