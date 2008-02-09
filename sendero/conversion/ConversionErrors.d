module sendero.conversion.ConversionErrors;

public import sendero.msg.Error;

abstract class ConversionError : FieldError
{
	
}

abstract class FilterError : FieldError
{

}

class TimeConversionError : ConversionError
{
	this()
	{
		register("TimeFormat");
	}
}

class DateConversionError : ConversionError
{
	this()
	{
		register("DateFormat");
	}
}

class DateTimeConversionError : ConversionError
{
	this()
	{
		register("DateTimeFormat");
	}
}

class NumberConversionError : ConversionError
{
	this()
	{
		register("NumberFormat");
	}
}

class IntegerConversionError : NumberConversionError
{
	this()
	{
		register("IntegerFormat");
	}
}