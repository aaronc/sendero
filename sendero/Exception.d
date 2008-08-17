/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.Exception;

class SenderoException : Exception
{
	this(char[] msg, Exception next = null)
	{
		super(msg, next);
	}
}

class ConversionNotAvailableException : Exception
{
	this(char[] msg)
	{
		super(msg);
	}
}

class MessageSinkNotFoundException : Exception
{
	this(char[] msg)
	{
		super(msg);
	}
}

/*
 *  DB Exceptions
 *  
 * 
 * 
 * 
 */

