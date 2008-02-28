module sendero.time.LocalTime;

import tango.time.Time;
import sendero.time.internal.TimeZoneImpl;

struct LocalTime
{
	public Time utc;
	public TimeZone zone;

	Time local()
	{
		return zone.toLocal(utc);
	}
	
	TimeSpan offset()
	{
		return zone.getOffset(utc);
	}
}

struct TimeZone
{
	private uint idx;
	
	bool setByName(char[] name)
	{
		return getTZIdxByName(name, idx);
	}
	
	char[] name()
	{
		return zones[idx].name;	
	}

	Time toLocal(Time utc)
	{
		return zones[idx].toLocal(utc);
	}

	Time toUtc(Time local)
	{
		return zones[idx].toUtc(local);
	}

	TimeSpan getOffset(Time utc)
	{
		return zones[idx].calcOffsetFromUTC(utc);
	}	
}

alias TimeZone LocalClock;

version(Unittest)
{
import tango.time.Clock;
import tango.util.Convert;
import tango.time.chrono.Gregorian;
unittest
{
	TimeZone tz;
	assert(tz.getOffset(Clock.now).ticks == 0);
	assert(tz.setByName("America/New_York"));
	
	auto hrs = tz.getOffset(Clock.now).hours;
	assert(hrs == -5, to!(char[])(hrs));

	assert(tz.setByName("Europe/London"));
	
	hrs = tz.getOffset(Clock.now).hours;
	assert(hrs == 0, to!(char[])(hrs));

	assert(tz.setByName("America/Los_Angeles"));
	
	auto time = Gregorian.generic.toTime(2003, 4, 15, 3, 7, 15, 0, 1);
	TimeSpan span;
	for(uint i = 0; i < 1e6; ++i)
		span = tz.getOffset(time);
	hrs = span.hours;
	assert(hrs == -7, to!(char[])(hrs));
}
}