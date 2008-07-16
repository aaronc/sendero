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
	idx = 0;
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
		return utc + calcOffsetViaUtc(utc);
	}

	Time toUtc(Time local)
	{
		return local - calcOffsetViaLocal(local);
	}

	TimeSpan calcOffsetViaUtc(Time utc)
	{
		if(ruleIdx < 0)
			return offset;

		return rules[ruleIdx].calcDSTOffsetViaUtc(utc, offset) + offset;
	}
	
	TimeSpan calcOffsetViaLocal(Time local)
	{
		if(ruleIdx < 0)
			return offset;

		return rules[ruleIdx].calcDSTOffsetViaLocal(local, offset) + offset;
	}

	char[] format(Time utc)
	{
		if(ruleIdx < 0)
			return stdFormat;

		if(rules[ruleIdx].calcDSTOffsetViaUtc(utc, offset).ticks) {
			return dstFormat;
		}
		else return stdFormat;
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
	private Time[] cache;

	TimeSpan calcDSTOffsetViaUtc(Time utc, TimeSpan offset)
	{
		TimeSpan etc()
		{
			uint yr, mon, day, doy, dow, era;
			Gregorian.generic.split(utc, yr, mon, day, doy, dow, era);

			if(mon > onRules[0].month && mon < onRules[1].month)
				return offsets[0];

			if(mon < onRules[0].month || mon > onRules[1].month)
				return offsets[1];
			
			if(mon == onRules[0].month) {
				auto dst = getDSTTimeForYear(yr, onRules[0]);
				if(utc < dst)
					return offsets[1];
				else
					return offsets[0];
			}
			else {
				auto dst = getDSTTimeForYear(yr, onRules[1]);
				if(utc < dst)
					return offsets[0];
				else
					return offsets[1];
			}			
		}

		if(!cache.length) updateCache;
		
		if(!atUtc) utc += offset;
		
		if(utc < cache[2]) {
			if(utc >= cache[1])
				return offsets[1];
			else if(utc >= cache[0])
				return offsets[0];
			else return etc;
		}
		else if(utc < cache[4]) {
			if(utc >= cache[3])
				return offsets[1];
			else if(utc >= cache[2])
				return offsets[0];
		}
		else if(utc < cache[5])
			return offsets[1];
		else return etc;
	}
	
	TimeSpan calcDSTOffsetViaLocal(Time local, TimeSpan offset)
	{
		TimeSpan etc()
		{
			uint yr, mon, day, doy, dow, era;
			Gregorian.generic.split(local, yr, mon, day, doy, dow, era);

			if(mon > onRules[0].month && mon < onRules[1].month)
				return offsets[0];

			if(mon < onRules[0].month || mon > onRules[1].month)
				return offsets[1];
			
			if(mon == onRules[0].month) {
				auto dst = getDSTTimeForYear(yr, onRules[0]);
				if(local + offsets[1] < dst)
					return offsets[1];
				else
					return offsets[0];
			}
			else {
				auto dst = getDSTTimeForYear(yr, onRules[1]);
				if(local + offsets[0] < dst)
					return offsets[0];
				else
					return offsets[1];
			}			
		}

		if(!cache.length) updateCache;
		
		if(atUtc) local -= offset;
		
		if(local + offsets[1] < cache[2]) {
			if(local + offsets[1] >= cache[1])
				return offsets[1];
			else if(local + offsets[0] >= cache[0])
				return offsets[0];
			else return etc;
		}
		else if(local + offsets[1] < cache[4]) {
			if(local + offsets[1] >= cache[3])
				return offsets[1];
			else if(local + offsets[0] >= cache[2])
				return offsets[0];
		}
		else if(local + offsets[1] < cache[5])
			return offsets[1];
		else return etc;
	}

	void updateCache()
	{
		Time[] times = new Time[6];
		alias Gregorian.generic gg;
		auto yr = gg.getYear(Clock.now);
		--yr;
		times[0] = getDSTTimeForYear(yr, onRules[0]);
		times[1] = getDSTTimeForYear(yr, onRules[1]);

		++yr;
		times[2] = getDSTTimeForYear(yr, onRules[0]);
		times[3] = getDSTTimeForYear(yr, onRules[1]);

		++yr;
		times[4] = getDSTTimeForYear(yr, onRules[0]);
		times[5] = getDSTTimeForYear(yr, onRules[1]);
		
		cache = times;
		
	}

	static Time getDSTTimeForYear(uint yr, OnRule onrule)
	{
		Time onTime;
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
		return onTime;
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

	// Test Rule.getDSTTyimeForYear
			uint idx;
			assert(getTZIdxByName("America/New_York", idx));
			auto zone = zones[idx];
			auto ridx = zone.ruleIdx;
			auto rule = rules[ridx];
			
			/+Stdout.formatln("{}, {}",
				pt(Rule.getDSTTimeForYear(2007, rule.onRules[0])),
				pt(gg.toTime(2007, 3, 11, 2, 0, 0, 0, 1))
			);+/
			
			assert(	Rule.getDSTTimeForYear(2007, rule.onRules[0]) ==
						gg.toTime(2007, 3, 11, 2, 0, 0, 0, 1));
			
			assert( rule.calcDSTOffsetViaLocal(gg.toTime(2007, 3, 12, 3, 0, 0, 0, 1)
				, zone.offset).hours == 1);
			
			assert( rule.calcDSTOffsetViaLocal(gg.toTime(2007, 11, 4, 0, 30, 0, 0, 1)
				, zone.offset).hours == 1);
			
			assert(rule.calcDSTOffsetViaUtc(gg.toTime(2007, 11, 4, 5, 30, 0, 0, 1)
				, zone.offset).hours == 1);
			
			assert(	Rule.getDSTTimeForYear(2007, rule.onRules[1]) ==
				gg.toTime(2007, 11, 4, 1, 0, 0, 0, 1));
			
			assert( rule.calcDSTOffsetViaLocal(gg.toTime(2007, 11, 4, 1, 30, 0, 0, 1)
				, zone.offset).hours == 0);
			
			assert(rule.calcDSTOffsetViaUtc(gg.toTime(2007, 11, 4, 6, 30, 0, 0, 1)
				, zone.offset).hours == 0);
			
			assert( rule.calcDSTOffsetViaLocal(gg.toTime(2008, 3, 9, 1, 45, 0, 0, 1)
				, zone.offset).hours == 0);
			
			assert(	Rule.getDSTTimeForYear(2008, rule.onRules[0]) ==
				gg.toTime(2008, 3, 9, 2, 0, 0, 0, 1));
		
			assert(	Rule.getDSTTimeForYear(2008, rule.onRules[1]) ==
				gg.toTime(2008, 11, 2, 1, 0, 0, 0, 1));
			
			assert(zone.calcOffsetViaUtc(gg.toTime(2007, 3, 17, 10, 40, 0, 0, 1)).hours == -4);
			
			Stdout.formatln("{}, {}", pt(zone.toLocal(gg.toTime(2007, 3, 17, 10, 40, 0, 0, 1))),
				pt(gg.toTime(2007, 3, 17, 6, 40, 0, 0, 1))
				);
			
			assert(getTZIdxByName("Europe/Paris", idx));
			zone = zones[idx];
			ridx = zone.ruleIdx;
			rule = rules[ridx];
			
			assert(zone.calcOffsetViaUtc(gg.toTime(2007, 3, 25, 0, 59, 59, 0, 1)).hours == 1);
			
			assert(	Rule.getDSTTimeForYear(2007, rule.onRules[0]) ==
				gg.toTime(2007, 3, 25, 1, 0, 0, 0, 1));
			
			assert(zone.calcOffsetViaUtc(gg.toTime(2007, 3, 25, 2, 40, 0, 0, 1)).hours == 2);
		
			assert(	Rule.getDSTTimeForYear(2007, rule.onRules[1]) ==
				gg.toTime(2007, 10, 28, 1, 0, 0, 0, 1));
			
			assert(	Rule.getDSTTimeForYear(2008, rule.onRules[0]) ==
				gg.toTime(2008, 3, 30, 1, 0, 0, 0, 1));
			
			assert(	Rule.getDSTTimeForYear(2008, rule.onRules[1]) ==
				gg.toTime(2008, 10, 26, 1, 0, 0, 0, 1));
			
			
			assert(zone.calcOffsetViaUtc(gg.toTime(2010, 3, 28, 0, 45, 0, 0, 1)).hours == 1);
			assert(zone.calcOffsetViaUtc(gg.toTime(2010, 3, 28, 1,15, 0, 0, 1)).hours == 2);
			assert(zone.calcOffsetViaUtc(gg.toTime(2010, 4, 28, 1,15, 0, 0, 1)).hours == 2);
			assert(zone.calcOffsetViaUtc(gg.toTime(2010, 10, 31, 0, 45, 0, 0, 1)).hours == 2);
			assert(zone.calcOffsetViaUtc(gg.toTime(2010, 10, 31, 1, 15, 0, 0, 1)).hours == 1);
			
		// Test
}
}