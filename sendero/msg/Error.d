module sendero.msg.Error;

public import sendero.msg.Msg;

alias MsgMap ErrorMap;

class Error : Msg
{
	this()
	{
		register("Error");
	}
}

abstract class FieldError : Error
{
	
}

abstract class ValidationError : FieldError
{
	
}

class ExistenceValidationError : ValidationError
{
	this()
	{
		register("Existence");
	}
}

abstract class LengthValidationError : ValidationError
{
	this(uint len)
	{
		this.len = len;
	}
	private uint len;
	uint getLengthParameter() { return len; }
}

final class MinLengthValidationError : LengthValidationError
{
	this(uint len)
	{
		super(len);
		register("MinLength");
	}
}

final class MaxLengthValidationError : LengthValidationError
{
	this(uint len)
	{
		super(len);
		register("MaxLength");
	}
}

abstract class IntegerValueValidationError : ValidationError
{
	this(long val)
	{
		this.val = val;
	}
	private long val;
	long getValueParameter() { return val; }
}

final class MinValueValidationError : IntegerValueValidationError
{
	this(long val)
	{
		super(val);
		register("MinValue");
	}
}

final class MaxValueValidationError : IntegerValueValidationError
{
	this(long val)
	{
		super(val);
		register("MaxValue");
	}
}


abstract class FloatValueValidationError : ValidationError
{
	this(double val)
	{
		this.val = val;
	}
	private double val;
	double getValueParameter() { return val; }
}

final class MinFloatValueValidationError : FloatValueValidationError
{
	this(double val)
	{
		super(val);
		register("MinValue");
	}
}

final class MaxFloatValueValidationError : FloatValueValidationError
{
	this(double val)
	{
		super(val);
		register("MaxValue");
	}
}

final class LowerBoundValueValidationError : FloatValueValidationError
{
	this(double val)
	{
		super(val);
		register("LowerBound");
	}
}

final class UpperBoundValueValidationError : FloatValueValidationError
{
	this(double val)
	{
		super(val);
		register("UpperBound");
	}
}

class FormatValidationError : ValidationError
{
	this()
	{
		register("Format");
	}
}

class EmailFormatValidationError : FormatValidationError
{
	this()
	{
		register("EmailFormat");
	}
}

class UrlFormatValidationError : FormatValidationError
{
	this()
	{
		register("UrlFormat");
	}
}

abstract class ConversionError : FieldError
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

unittest
{
	auto err = new MinLengthValidationError(5);
	assert(err.toString == "sendero.msg.Error.MinLengthValidationError", err.toString);
	assert(err.getLengthParameter == 5);
}