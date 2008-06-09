/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

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