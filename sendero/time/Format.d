module sendero.time.Format;

import sendero.time.LocalTime;
import sendero_base.util.TimeConvert;
//import tango.time.Clock;
import tango.time.chrono.Gregorian;
import tango.time.Time;
import Int = tango.text.convert.Integer;

alias Int.toString itoa;

void uitoaFixed(uint len)(uint x, char[] res)
{
	if(res.length < len)
		throw new Exception("Insufficient buffer size");
	
	const char[] digits = "0123456789";
	for(uint i = 0; i < len; ++i)
	{
		res[len - i - 1] = digits[ x % 10];
		x /= 10;
	}
}

char[] formatRFC3339(Time t)
{
	char[] res = new char[20];
	//auto dt = Clock.toDate(t);
	uint yr, mo, day, doy, dow, era;
	Gregorian.generic.split(t, yr, mo, day, doy, dow, era);
	auto time = t.time;
	uitoaFixed!(4)(yr, res);
	res[4] = '-';
	uitoaFixed!(2)(mo, res[5 .. 7]);
	res[7] = '-';
	uitoaFixed!(2)(day, res[8 .. 10]);
	res[10] = 'T';
	uitoaFixed!(2)(time.hours, res[11..13]);
	res[13] = ':';
	uitoaFixed!(2)(time.minutes, res[14..16]);
	res[16] = ':';
	uitoaFixed!(2)(time.seconds, res[17..19]);
	res[19] = 'Z';
	return res;
}

private struct Format
{
enum F {
	G,
	GGGG,
	GGGGG,
//	y,
	yy,
//	yyy,
	yyyy,
//	yyyyy,
	Y,
	u,
	Q,
	QQQ,
	QQQQ,
	q,
	qqq,
	qqqq,
	M,
	MMM,
	MMMM,
	MMMMM,
	L,
	LLL,
	LLLLL,
	LLLLLL,
	l,
	w,
	W,
	d,
	D,
	F,
	g,
	E,
	EEEE,
	EEEEE,
	e,
	eee,
	eeee,
	eeeee,
	c,
	ccc,
	cccc,
	ccccc,
	a,
	h,
	H,
	K,
	k,
	j,
	m,
	s,
	S,
	A,
	z,
	zzzz,
	Z,
	ZZZZ,
	v,
	vvvv,
	V,
	VVVV,
	String
};
	F[] ops;
	char[][] strings;
}
/+
char[] formatDateTime_(Time t, Format pattern)
{
	auto dt = Clock.toDate(t);
	char[] res;
	uint strCtr = 0;
	foreach(f; pattern.ops)
	{
	switch(f.op)
	{
	case F.String:
		debug assert(strCtr < patternstrings.length);
		res ~= pattern.strings[strCtr];
		++strCtr;
		break;
	case F.yy:
		
	case F.yyyy:
		
	}
	}
}
+/

char[] formatDateTime_(Time t)
{
	//auto dt = Clock.toDate(t);
	auto dt = toDate(t);
	char[] ampm = "AM";
	if(dt.time.hours > 12) {
		dt.time.hours = dt.time.hours - 12;
		ampm = "PM";
	}
	
	return	itoa(dt.date.month) ~ '/' ~
			itoa(dt.date.day) ~ '/' ~ 
			itoa(dt.date.year) ~ ' ' ~
			itoa(dt.time.hours) ~ ':' ~
			itoa(dt.time.minutes) ~ ' ' ~ ampm;
}
/+
char[] formatLocalTime(LocalTime lt)
{
	auto dt = Clock.toDate(lt.utc);
	char[] ampm = "AM";
	if(dt.time.hours > 12) {
		dt.time.hours = dt.time.hours - 12;
		ampm = "PM";
	}
	
	return	itoa(dt.date.month) ~ '/' ~
			itoa(dt.date.day) ~ '/' ~ 
			itoa(dt.date.year) ~ ' ' ~
			itoa(dt.time.hours) ~ ':' ~
			itoa(dt.time.minutes) ~ ' ' ~ ampm;
}
+/