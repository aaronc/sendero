module sendero.conversion.IConverter;

public import sendero.msg.Error;
public import sendero.http.Params;

interface IAbstractConverter
{
	
}

interface IConverter(T) : IAbstractConverter
{
	Error convert(Param p, inout T t);
}