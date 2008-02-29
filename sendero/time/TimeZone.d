/*
 * Authors: Aaron Craelius
 */
module sendero.time.TimeZone;

import tango.time.Time;
import sendero.time.internal.TimeZoneImpl;

/**
 * Represents a time zone (as defined by the public domain zoneinfo data set) which should correspond
 * to the most recent political/geographical time zone information available.  Allows conversions to and from UTC
 * and Local times with daylight savings times taken into account automatically.
 * 
 * Note that this calendar is proleptic -that is historical dates and times will be calculated with respect to the current time zone rules.
 * If local conventions have changed recently (which they do) that historical daylight savings time may be calculated incorrectly
 * for some dates. If this is important to you that you can look at the zoneinfo data yourself and work with the structures and functions
 * in sendero.time.internal.TimeZoneImpl to perform the correct calculations yourself.  Since it is assumed that the most important
 * function of this library is for providing the correct local time for present, future, and possibly recent past events, this limitation
 * of the library is acceptable for these purposes.  It is simply not a library for historical timezone calculations!  It is primarily for the present
 * and near future.   
 * 
 */
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

	TimeSpan getOffsetViaUtc(Time utc)
	{
		return zones[idx].calcOffsetViaUtc(utc);
	}	
	
	TimeSpan getOffsetViaLocal(Time local)
	{
		return zones[idx].calcOffsetViaUtc(local);
	}

	char[] format(Time utc)
	{
		return zones[idx].format(utc);
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
	alias Gregorian.generic gg;
	
	TimeZone tz;
	assert(tz.getOffsetViaUtc(Clock.now).ticks == 0);
	assert(tz.setByName("America/New_York"));
	
	auto hrs = tz.getOffsetViaUtc(Clock.now).hours;
	assert(hrs == -5, to!(char[])(hrs));

	assert(tz.setByName("Europe/London"));
	
	hrs = tz.getOffsetViaUtc(Clock.now).hours;
	assert(hrs == 0, to!(char[])(hrs));

	assert(tz.setByName("America/Los_Angeles"));
	
	auto time = gg.toTime(2003, 4, 15, 3, 7, 15, 0, 1);
	TimeSpan span;
	for(uint i = 0; i < 1e6; ++i)
		span = tz.getOffsetViaUtc(time);
	hrs = span.hours;
	assert(hrs == -7, to!(char[])(hrs));

	assert(tz.format(time) == "PDT", tz.format(time));

}
}