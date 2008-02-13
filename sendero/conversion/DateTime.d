module sendero.conversion.DateTime;

import tango.time.Clock;

import sendero.convert.DateTime;
import sendero.conversion.IConverter;
import sendero.conversion.ConversionErrors;

class ExactDateTimeConverter : ExactDateTimeParser, IConverter!(DateTime), IConverter!(Time), IConverter!(Date), IConverter!(TimeOfDay)
{
	private this(char[] format, Error error = null)
	{
		super(format);
		if(!error) error = DateTimeConversionError();
		this.error = error;
	}
	private Error error;
	
	static ExactDateTimeConverter opCall(char[] format, Error error = null)
	{
		return new ExactDateTimeConverter(format, error);
	}
	
	Error convert(Param p, inout DateTime dt)
	{
		if(p.type != ParamT.Value) return null;
		auto str = p.val;
		if(!super.convert(str, dt))
			return error;
		return null;
	}
	
	Error convert(Param p, inout Time t)
	{
		DateTime dt;
		auto res = convert(p, dt);
		if(!res) {
			t = Clock.fromDate(dt);
			return null;
		}
		return res;
	}
	
	Error convert(Param p, inout Date d)
	{
		DateTime dt;
		auto res = convert(p, dt);
		if(!res) {
			d = dt.date;
			return null;
		}
		return res;
	}
	
	Error convert(Param p, inout TimeOfDay t)
	{
		DateTime dt;
		auto res = convert(p, dt);
		if(!res) {
			t = dt.time;
			return null;
		}
		return res;
	}
}

alias ExactDateTimeConverter ExactTimeConverter;

ExactDateTimeConverter ExactDateConverter(char[] format, Error error = null)
{
	if(!error) error = DateConversionError();
	return ExactDateTimeConverter(format, error); 
}

ExactDateTimeConverter ExactTimeOfDayConverter(char[] format, Error error = null)
{
	if(!error) error = TimeConversionError();
	return ExactDateTimeConverter(format, error); 
}

class SplitDateTimeConverter : IConverter!(DateTime)
{
	private char[][2] paramNames;
	
	Error convert(Param p, inout DateTime dt)
	{
		return DateTimeConversionError();
	}
}