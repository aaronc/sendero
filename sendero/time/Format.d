module sendero.time.Format;

import sendero.time.LocalTime;
import tango.time.Clock;
import tango.time.Time;
import Int = tango.text.convert.Integer;

alias Int.toString itoa;

private struct F 
{
enum {
	G,
	GGGG,
	GGGGG,
	y,
	yy,
	yyy,
	yyyy,
	yyyyy,
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
	int op;
	char[] str;
}

char[] formatDateTime_(Time t, F[] pattern)
{
	auto dt = Clock.toDate(t);
	char[] res;
	foreach(f; pattern)
	{
	switch(f.op)
	{
	}
	}
}


char[] formatDateTime_(Time t)
{
	auto dt = Clock.toDate(t);
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
