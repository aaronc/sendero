import tango.io.Stdout;
import tango.io.stream.LineStream;
import tango.io.FileConduit;
import tango.io.Buffer;
import tango.io.model.IConduit;
import tango.io.File;
import Util = tango.text.Util;
import Integer = tango.text.convert.Integer;
import tango.time.Time;
import Array = tango.core.Array;
import tango.io.GrowBuffer;

import sendero.time.internal.TimeZoneImpl;

/*
* This script should be ran against the data in the zoneinfo database.  The URL at time
* of writing is ftp://elsie.nci.nih.gov/pub/tzdata2007k.tar.gz for the data and the URL for
* zoneinfo is http://www.twinsun.com/tz/tz-link.htm.
*/

char[] header = `
module sendero.time.data.ZoneInfo;

import sendero.time.internal.TimeZoneImpl;

`;

char[][] getFields(char[] line)
{
	char[][] fields;

	size_t a = 0;
	size_t b = 0;
	auto len = line.length;
	while(b < len) {
		a = b;
		while(a < len && Util.isSpace(line[a])) {
			++a;
		}
		b = a;
		while(b < len && !Util.isSpace(line[b])) {
			++b;
		}
		if(b > a) fields ~= line[a .. b];
	}

	return fields;
}

TimeSpan parseOffset(char[] offset)
{
	bool neg = false;
	if(offset.length && offset[0] == '-') {
		neg = true;
		offset = offset[1 .. $];
	}

	auto vals = Util.split(offset, ":");
	long secs = 0;
	if(vals.length) secs += Integer.parse(vals[0]) * 60 * 60;
	if(vals.length > 1) secs += Integer.parse(vals[1]) * 60;
	if(vals.length > 2) secs += Integer.parse(vals[2]);
	if(neg) secs = secs * -1;
	return TimeSpan.seconds(secs);
}

struct ZoneInfo
{
	char[] name;
	TimeSpan offset;
	char[] rule;
	char[] format;

	static ZoneInfo opCall(char[] n, char[] o, char[] r, char[] f)
	{
		ZoneInfo z;
		z.name = n;
		z.offset = parseOffset(o);
		z.rule = r;
		z.format = f;
		return z;
	}
}

ZoneInfo[] zoneInfos;

void addZone(char[] n, char[] o, char[] r, char[] f)
{
	ZoneInfo zone = ZoneInfo(n, o, r, f);
	zoneInfos ~= zone;
	/+if(f == "%s") return;

	auto pf = zone.format in formats;
	if(pf) {
		if(pf.offset != zone.offset) Stdout(pf.name ~ " conflicts with " ~ zone.name ~ ":" ~ pf.offset ~ " vs " ~ zone.offset).newline;
		if(pf.rule != zone.rule) Stdout(pf.name ~ " conflicts with " ~ zone.name ~ ":" ~ pf.rule ~ " vs " ~ zone.rule).newline;
	}
	else formats[zone.format] = zone;+/
}

/+struct Zone
{
	char[] name;
	TimeSpan offset;
	uint rule;
	char[] stdFormat;
	char[] dstFormat;
}+/

ZoneImpl[] zones;

void compileZones()
{
	foreach(zi; zoneInfos)
	{
		CompiledRule* pRule = null;
		ZoneImpl z;
		z.name = zi.name;
		z.offset = zi.offset;
		if(zi.rule == "-") {
			z.ruleIdx = -1;
		}
		else {
			pRule = zi.rule in compiledRules;
			if(!pRule) {
				Stdout.formatln("Unable to find DST rule identified as {} for {}. Maybe DST is no longer used in this region.", zi.rule, z.name);
				z.ruleIdx = -1;
			}
			else z.ruleIdx = pRule.idx;
		}
		
		if(Util.containsPattern(zi.format, "%s")) {
			if(!pRule) {
				auto pLetter = zi.rule in stdLetters;
				assert(pLetter, "Unable to find format letter for format rule " ~ zi.rule ~ " for " ~ z.name);
				z.stdFormat = Util.substitute(zi.format, "%s", *pLetter);
				z.dstFormat = z.stdFormat;
			}
			else {
				z.stdFormat = Util.substitute(zi.format, "%s", pRule.offLetter);
				z.dstFormat = Util.substitute(zi.format, "%s", pRule.onLetter);
			}
		}
		else if(Util.contains(zi.format, '/')) {
			auto	formats = Util.split(zi.format, "/");
			assert(formats.length == 2);
			z.stdFormat = formats[0];
			z.dstFormat = formats[1];
		}
		else {
			z.stdFormat = zi.format;
			z.dstFormat = zi.format;
		}
		
		zones ~= z;
	}
}

//Zone[char[]] formats;

enum RuleType { Std, Utc, Local };

void createOnRule(char[] In, char[] On, char[] At, TimeSpan save, ref OnRule rule, ref RuleType type)
{	
	rule.month = Array.find(months, In) + 1;
	assert(rule.month <= 12);

	if(On.length == 7 && On[0..4] == "last") {
	//	rule.type = OnRule.Type.Last;
		rule.onLast = true;
		rule.dow = Array.find(days, On[4..7]);
		assert(rule.day <= 6);
	}
	/+else if(On.length == 8 && On[0..5] == "first") {
		rule.type = OnRule.Type.Last;
		rule.dow = Array.find(days, On[5..8]);
		assert(rule.day <= 6);
	}+/
	else if(On.length > 5 && On[3..5] == ">=") {
		//rule.type = OnRule.Type.Day;
		rule.onLast = false;
		rule.dow = Array.find(days, On[0..3]);
		assert(rule.dow <= 6);
		rule.day = Integer.parse(On[5..$]);
		assert(rule.day <= 31);
	}
	else assert(false, On);

	assert(At.length);
	if(At[$-1] == 's') {
		//rule.atType = OnRule.AtType.Standard;
		type = RuleType.Std;
		rule.at = parseOffset( At[0..$-1] );
	}
	else if(At[$-1] == 'u') {
		//rule.atType = OnRule.AtType.UTC;
		type = RuleType.Utc;
		rule.at = parseOffset( At[0..$-1] );
	}
	else {
		//rule.atType = OnRule.AtType.Local;
		type = RuleType.Local;
		rule.at = parseOffset(At);
	}

	return rule;
}

char[][] months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
char[][] days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
struct SingleRule
{
	char[]	name;
	OnRule	on;
	RuleType type;
	TimeSpan save;
	char[] letter;

	static SingleRule opCall(char[] name, char[] In, char[] On, char[] At, char[] save, char[] letter)
	{
		SingleRule r;
		r.name = name;
		r.save = parseOffset(save);
		createOnRule(In, On, At, r.save, r.on, r.type);
		r.letter = letter;
		return r;
	}
}
SingleRule[] singleRules;

void addRule(char[] name, char[] In, char[] On, char[] At, char[] save, char[] letter)
{
	singleRules ~= SingleRule(name, In, On, At, save, letter);
}

struct CompiledRule
{
	char[] name;
	OnRule on;
	OnRule off;
	TimeSpan save;
	char[] onLetter;
	char[] offLetter;
	int idx;
	RuleType type;
}

CompiledRule[char[]] compiledRules;

Rule[] rules;

void compileRules()
{
	TimeSpan t0 = TimeSpan(0);
	foreach(sr; singleRules)
	{
		auto pr = sr.name in compiledRules;
		if(pr) {
			if(sr.save != t0) {
				assert(pr.save == t0);
				pr.on = sr.on;
				pr.save = sr.save;
				if(sr.letter != "-") pr.onLetter = sr.letter;
			}
			else {
				assert(pr.save != t0);
				pr.off = sr.on;
				if(sr.letter != "-") pr.offLetter = sr.letter;
			}
			assert(pr.type == sr.type);
		}
		else {
			CompiledRule r;
			r.name = sr.name;
			if(sr.save != t0) {
				r.save = sr.save;
				r.on = sr.on;
				if(sr.letter != "-") r.onLetter = sr.letter;
			}
			else {
				r.off = sr.on;
				if(sr.letter != "-") r.offLetter = sr.letter;
			}
			r.type = sr.type;
			compiledRules[r.name] = r;
		}
	}

	foreach(k, ref v; compiledRules)
	{
		Rule r;
		r.name = v.name;
		if(v.on.month < v.off.month) {
			r.onRules[0] = v.on;
			r.onRules[1] = v.off;
			r.offsets[0] = v.save;
			r.offsets[1] = TimeSpan(0);
		}
		else {
			r.onRules[0] = v.off;
			r.onRules[1] = v.on;
			r.offsets[0] = TimeSpan(0);
			r.offsets[1] = v.save;
		}
		switch(v.type)
		{
		case RuleType.Utc:
			r.atUtc = true;
			break;
		case RuleType.Local:
			if(r.offsets[0].ticks) r.onRules[1].at -= v.save;
			else r.onRules[0].at -= v.save;
		case RuleType.Std:
		default:
			r.atUtc = false;
			break;
		}
		v.idx = rules.length;
		rules ~= r;
	}
}

char[][char[]] stdLetters;

void str(char[] val, void delegate(void[]) put)
{
	put(`"`);
	put(val);
	put(`"`);
}

void itoa(long i, void delegate(void[]) put)
{
	put(Integer.toString(i));
}

void printOnRule(OnRule or, void delegate(void[]) put)
{
	put("{");
	
	itoa(or.onLast, put);
	put(",");
	
	itoa(or.month, put);
	put(",");

	itoa(or.dow, put);
	put(",");

	itoa(or.day, put);
	put(",");

	put("{");
		itoa(or.at.ticks, put);
	put("}}");
}

void printDataFile(void delegate(void[]) put)
{
	put(header);

	put("Rule[] rules = [\n");
	foreach(r; rules)
	{
		put("\t{");
		
		str(r.name, put);
		put(",[");
		
		printOnRule(r.onRules[0], put);
		put(",");
		
		printOnRule(r.onRules[1], put);
		put("],");

		//put("TimeSpan(");
		put("[{");
			itoa(r.offsets[0].ticks, put);
		put("}");
		//put(")");
		put(",");

		put("{");
		itoa(r.offsets[1].ticks, put);
		put("}],");


		itoa(r.atUtc, put);
		
		put("},\n");
	}
	put("];\n\n");

	put("ZoneImpl[] zones = [\n");
	
	//UTC
	put("\t{");
	str("Etc/UTC", put);
	put(",{");
	itoa(0, put);
	put("},");
	itoa(-1, put);
	put(",");
	str("UTC", put);
	put(",");
	str("UTC", put);
	put("},\n");


	foreach(z; zones)
	{
		put("\t{");
		str(z.name, put);
		put(",{");
		itoa(z.offset.ticks, put);
		put("},");
		itoa(z.ruleIdx, put);
		put(",");
		str(z.stdFormat, put);
		put(",");
		str(z.dstFormat, put);
		put("},\n");
	}
	put("];\n");
}


void extract(InputStream input)
{
	auto lines = new LineInput(input);

	enum { Std, Zone };
	int st;
	char[] curZone;

	foreach(line; lines)
	{
		if(!line.length)
			continue;
		if(line[0] == '#')
			continue;

		char[][] fields = getFields(line);
		
		if(line.length > 4 && line[0 .. 4] == "Zone") {
			assert(fields.length > 1, line);
			curZone = fields[1];
			//Stdout.formatln("Found Zone: {}", curZone);
			if(fields.length < 6 || fields[5].length == 0 || fields[5][0] == '#')
			{
				assert(fields.length >= 5);
				//Stdout.formatln("Zone: {}, Offset: {}, Rules: {}, Format: {}", curZone, fields[2], fields[3], fields[4]);
				addZone(curZone, fields[2], fields[3], fields[4]);
			}
			else st = Zone;
		}
		else if(line.length > 4 && line[0 .. 4] == "Link")
		{
			assert(fields.length > 2);
			//Stdout.formatln("Link From:{}, To: {}", fields[1], fields[2]);
		}
		else if(line.length > 4 && line[0 .. 4] == "Rule")
		{
			if(fields.length > 3)
			{
				if(fields[3] == "max")
				{
					assert(fields.length > 9);
					//Stdout.formatln("Rule: {}, In: {}, On: {}, At: {}, Save:{}, Letter:{}, Type: {}",
					//	fields[1], fields[5], fields[6], fields[7], fields[8], fields[9], fields[4]);
					//assert(fields[4] == "-", fields[4]);
					addRule(fields[1], fields[5], fields[6], fields[7], fields[8], fields[9]);
				}
				else
				{
					auto offset = parseOffset(fields[8]);
					auto letter = fields[9];
					if(letter == "-") letter = "";
					if(!offset.ticks) {
						stdLetters[fields[1]] = letter;
					}
				}
			}
		}
		else if(st == Zone) {
			if(fields.length < 3)
			{
				st = Std;
			}
			else if(fields.length == 3 || fields[3].length == 0 || fields[3][0] == '#')
			{
				//Stdout.formatln("Zone: {}, Offset: {}, Rules: {}, Format: {}", curZone, fields[0], fields[1], fields[2]);
				addZone(curZone, fields[0], fields[1], fields[2]);
				//Stdout('\t')(line).newline;
			}
		}	
	}

	input.close;

	return null;
}

void main(char[][] args)
{
	char[] dir = ".";
	if(args.length > 1) {
		dir = args[1];
	}

	void doFile(char[] fname)
	{
		auto f = new File(dir ~ "/" ~ fname);
		auto buf = new Buffer(f.read);
		extract(buf);
	}

	doFile("africa");
	doFile("antarctica");
	doFile("australasia");
	doFile("europe");
	doFile("northamerica");
	doFile("pacificnew");
	doFile("southamerica");
	compileRules;
	//foreach(k, r; compiledRules)
	//	Stdout.formatln("Rule: {}, OnMon: {}, OffMon: {}, Save: {}, OnLetter:{}, OffLetter:{}", k, r.on.month, r.off.month, r.save.ticks, r.onLetter, r.offLetter);
	compileZones;

	auto res = new GrowBuffer;
	printDataFile((void[] val) {res.append(val.ptr, val.length);});
	//Stdout.copy(res);
	auto outFile = new File("../../sendero/time/data/ZoneInfo.d");
	outFile.write(res.slice);

	Stdout.formatln("Compiled {} time zones and {} rules.", zones.length, rules.length);
}

unittest
{
	auto fields = getFields("abc           abcd \t abcdefg  ");
	assert(fields.length == 3);
	assert(fields[0] == "abc");
	assert(fields[1] == "abcd");
	assert(fields[2] == "abcdefg");
}
