module sendero.time.internal.TimeZoneImpl;

import tango.time.Time;
import tango.time.Clock;
import tango.time.chrono.Gregorian;
public import sendero.time.data.ZoneInfo;

debug import tango.io.Stdout;

void trc(T...)(char[] str, T t)
{
	Stdout.formatln(str, t);
}

uint[char[]] zoneCache;

bool getTZIdxByName(char[] name, ref uint idx)
{
	auto pz = name in zoneCache;
	if(pz) { idx = *pz; return true; }
	foreach(i, tz; zones)
	{
		if(tz.name == name) {
			idx = i;
			return true;
		}
	}
	return false;
}

struct ZoneImpl
{
	char[] name;
	TimeSpan offset;
	int ruleIdx;
	char[] stdFormat;
	char[] dstFormat;

	Time toLocal(Time utc)
	{
		if(ruleIdx < 0)
			return utc + offset;

		return utc + rules[ruleIdx].calcOffset(utc, offset);
	}

	Time toUtc(Time local)
	{
		if(ruleIdx < 0)
			return local - offset;

		return local - rules[ruleIdx].calcOffset(local - offset, offset);
	}

	TimeSpan calcOffsetFromUTC(Time utc)
	{
		if(ruleIdx < 0)
			return offset;

		return rules[ruleIdx].calcOffset(utc, offset);
	}
}

struct OnRule
{
	bool onLast;
	uint month;
	uint dow;
	uint day;
	TimeSpan at;
}

struct Rule
{
	char[] name;
	OnRule[2] onRules;
	TimeSpan[2] offsets;
	bool atUtc;
	Time[] cache;

	TimeSpan calcOffset(Time utc, TimeSpan offset)
	{
		TimeSpan etc()
		{
			uint yr, mon, day, doy, dow, era;
			Gregorian.generic.split(utc, yr, mon, day, doy, dow, era);

			if(mon > onRules[0].month && mon < onRules[1].month)
				return offsets[0] + offset;

			if(mon < onRules[0].month || mon > onRules[1].month)
				return offsets[1] + offset;
			
			if(mon == onRules[0].month) {
				Time dst;
				getDSTTimeForYear(yr, onRules[0], dst);
				if(utc < dst)
					return offsets[1] + offset;
				else
					return offsets[0] + offset;
			}
			else {
				Time dst;
				getDSTTimeForYear(yr, onRules[1], dst);
				if(utc < dst)
					return offsets[0] + offset;
				else
					return offsets[1] + offset;
			}			
		}

		if(!cache.length) updateCache;
		
		if(!atUtc) utc += offset;
		
		if(utc < cache[2]) {
			if(utc >= cache[1])
				return offsets[1] + offset;
			else if(utc >= cache[0])
				return offsets[0] + offset;
			else return etc;
		}
		else if(utc < cache[4]) {
			if(utc >= cache[3])
				return offsets[1] + offset;
			else if(utc >= cache[2])
				return offsets[0] + offset;
		}
		else if(utc < cache[5])
			return offsets[1] + offset;
		else return etc;
	}

	void updateCache()
	{
		Time[] times = new Time[6];
		alias Gregorian.generic gg;
		auto yr = gg.getYear(Clock.now);
		--yr;
		getDSTTimeForYear(yr, onRules[0], times[0]);
		getDSTTimeForYear(yr, onRules[1], times[1]);

		++yr;
		getDSTTimeForYear(yr, onRules[0], times[2]);
		getDSTTimeForYear(yr, onRules[1], times[3]);

		++yr;
		getDSTTimeForYear(yr, onRules[0], times[4]);
		getDSTTimeForYear(yr, onRules[1], times[5]);
		
		cache = times;
		
	}

	static void getDSTTimeForYear(uint yr, OnRule onrule, ref Time onTime)
	{
		alias Gregorian.generic gg;
		if(!onrule.onLast) {
			onTime = gg.toTime(yr, onrule.month, onrule.day, 0, 0, 0, 0, 1);
			auto dow = gg.getDayOfWeek(onTime);
			int day = onrule.dow - dow;
			if(day < 0) day += 7;
			day += onrule.day;
			onTime = gg.toTime(yr, onrule.month, day, 0, 0, 0, 0, 1);
			
		}
		else {
			auto day = gg.getDaysInMonth(yr, onrule.month, 1);
			onTime = gg.toTime(yr, onrule.month, day, 0, 0, 0, 0, 1);
			auto dow = gg.getDayOfWeek(onTime);
			int dist = onrule.dow - dow;
			if(dist > 0) dist -= 7;
			day += dist;
			onTime = gg.toTime(yr, onrule.month, day, 0, 0, 0, 0, 1);
		}
		onTime += onrule.at;
	}
}