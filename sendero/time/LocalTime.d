module sendero.time.LocalTime;

import tango.time.Time;
public import sendero.time.TimeZone;

struct LocalTime
{
	public Time utc;
	public TimeZone zone;

	Time local()
	{
		return zone.toLocal(utc);
	}
	
	void local(Time local)
	{
		utc = local - zone.getOffsetViaLocal(local);
	}
	
	alias local time;
	
	TimeSpan offset()
	{
		return zone.getOffsetViaUtc(utc);
	}

	char[] format()
	{
		return zone.format(utc);
	}
}

version(Unittest)
{
import tango.time.Clock;
import tango.util.Convert;
import tango.time.chrono.Gregorian;
import tango.io.Stdout;
import sendero_base.util.ISO8601;

char[] pt(Time t)
{
	char[] res;
	printISO8601(Clock.toDate(t), (char[] val) { res ~= val;} );
	return res;
}

unittest
{
	alias Gregorian.generic gg;
}
}