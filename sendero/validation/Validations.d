/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.validation.Validations;

public import sendero.validation.ValidationErrors;

import tango.text.Regex;
import tango.core.Traits;
import tango.group.time;

debug import tango.util.Convert;

import sendero.util.Singleton;

abstract class AbstractValidation
{
	Error error;
}

abstract class Validation(T) : AbstractValidation
{
	abstract bool validate(T t);
}

class ExistenceValidation(T) : Validation!(T)
{
	static this()
	{
		existenceError = new ExistenceValidationError;
	}
	private static ExistenceValidationError existenceError;
	
	this()
	{
		error = existenceError;
	}
	
	bool validate(T t)
	{
		static if(isDynamicArrayType!(T))
			return t.length != 0;
		else static if(is(T == Time))
			return t.ticks != 0;
		else static if(is(T == DateTime))
			return t.date.month != 0 && t.date.day != 0 && t.date.year != 0;
	}
}

abstract class LengthValidation : Validation!(char[])
{
	this(uint len)
	{
		this.lengthParam = len;
	}
	uint lengthParam;
}

final class MinLengthValidation : LengthValidation
{
	this(uint len)
	{
		super(len);
		error = new MinLengthValidationError(len);
	}
	
	bool validate(char[] t) { return t.length >= lengthParam ? true : false;}
}

final class MaxLengthValidation : LengthValidation
{
	this(uint len)
	{
		super(len);
		error = new MaxLengthValidationError(len);
	}
	
	bool validate(char[] t) { return t.length <= lengthParam ? true : false;}
}

abstract class ValueValidation(T) : Validation!(T)
{
	this(T val)
	{
		this.valueParam = val;
	}
	T valueParam;
}

class MinValueValidation(T) : ValueValidation!(T)
{
	this(T val)
	{
		super(val);
		error = new MinValueValidationError(val);
	}
	
	bool validate(T t) {return t >= valueParam ? true : false;}
}

class MaxValueValidation(T) : ValueValidation!(T)
{
	this(T val)
	{
		super(val);
		error = new MaxValueValidationError(val);
	}
	
	bool validate(T t) {return t <= valueParam ? true : false;}
}

class FormatValidation : Validation!(char[])
{
	static this()
	{
		formatError = new FormatValidationError;
	}
	private static FormatValidationError formatError;
	
	this(char[] testRegex)
	{
		this.regex = Regex(testRegex);
		this.testRegex = testRegex;
		this.error = formatError;
	}
	
	private Regex regex;
	char[] testRegex;
	
	bool validate(char[] t) { return regex.test(t) != 0; }
}
/+
class UrlFormatValidation : FormatValidation
{	
	mixin Singleton!(UrlFormatValidation);
	
	this()
	{
		super(tango.text.Regex.url);
		error = new UrlFormatValidationError;
	}
}+/

class EmailValidation : FormatValidation
{
	mixin Singleton!(EmailValidation);
	
	private this()
	{
		super("[A-Za-z0-9_\\-]+@([A-Za-z0-9_\\-]+\\.)+[A-Za-z]+");
		error = new EmailValidationError;
	}
}

abstract class ConversionValidation : FormatValidation
{
	this(char[] testRegex)
	{
		super(testRegex);
	}
}
/+
class DateTimeConversionValidation :  ConversionValidation
{
	
}

class DateConversionValidation :  ConversionValidation
{
	
}

class TimeConversionValidation :  ConversionValidation
{
	
}

class NumberConversionValidation :  ConversionValidation
{
	
}

class IntegerConversionValidation : NumberConversionValidation
{
	
}+/

unittest
{
	auto v1 = new MinValueValidation!(int)(5);
	assert(v1.validate(7));
}