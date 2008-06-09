/** 
 * Copyright: Copyright (C) 2007-2008 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.Singleton;

template Singleton(X)
{
	static X opCall()
	{
		if(inst is null) {
			synchronized
			{
				if(inst is null)
				{
					inst = new X;
				}
			}
		}
		return inst;
	}
	private static X inst;
}