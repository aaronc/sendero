module sendero.Exception;

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

