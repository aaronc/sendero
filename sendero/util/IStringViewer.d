/** 
 * Copyright: Copyright (C) 2007 Aaron Craelius.  All rights reserved.
 * Authors:   Aaron Craelius
 */

module sendero.util.IStringViewer;

interface IStringViewer(Ch)
{
	Ch[] randomAccessSlice(size_t x, size_t y);
}