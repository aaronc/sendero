module sendero.conversion.ConversionErrors;

public import sendero.msg.Error;

import sendero.util.Singleton;

abstract class ConversionError : FieldError
{
	
}

abstract class FilterError : FieldError
{

}

class TimeConversionError : ConversionError
{
	mixin Singleton!(TimeConversionError);
	
	private this()
	{
		register("TimeFormat");
	}
}

class DateConversionError : ConversionError
{
	mixin Singleton!(DateConversionError);
	
	private this()
	{
		register("DateFormat");
	}
}

class DateTimeConversionError : ConversionError
{
	mixin Singleton!(DateTimeConversionError);
	
	private this()
	{
		register("DateTimeFormat");
	}
}

class NumberConversionError : ConversionError
{
	mixin Singleton!(NumberConversionError);
	
	private this()
	{
		register("NumberFormat");
	}
}

class IntegerConversionError : NumberConversionError
{
	mixin Singleton!(IntegerConversionError);
	
	private this()
	{
		super();
		register("IntegerFormat");
	}
}