/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.validation.ValidationErrors;

import tango.util.Convert;

public import sendero.msg.Error;
import sendero.util.Singleton;

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
	
	char[][char[]] getProperties()
	{
		char[][char[]] res;
		res["len"] = to!(char[])(len);
		return res;
	}
}

final class MinLengthValidationError : LengthValidationError
{
	static MinLengthValidationError[uint] errors;
	static MinLengthValidationError opCall(uint len)
	{
		auto pErr = len in errors;
		if(pErr) return *pErr;
		auto err = new MinLengthValidationError(len);
		errors[len] = err;
		return err;
	}
	
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
	
	char[][char[]] getProperties()
	{
		char[][char[]] res;
		res["val"] = to!(char[])(val);
		return res;
	}
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
	
	char[][char[]] getProperties()
	{
		char[][char[]] res;
		res["val"] = to!(char[])(val);
		return res;
	}
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

class EmailValidationError : FormatValidationError
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

unittest
{
	auto err = new MinLengthValidationError(5);
	assert(err.toString == "sendero.validation.ValidationErrors.MinLengthValidationError", err.toString);
	assert(err.getLengthParameter == 5);
}