module sendero.util.Unicode;

import Unicode = tango.text.convert.Utf;

char[] fromDecimalToUtf8(uint val)
{
	if(val <= 0x7f) {
		ubyte[1] x;
		x[0] = val;
		return cast(char[])x.dup;
	}
	else if(val <= 0x7ff) {
		ubyte[2] x;
		x[0] = 0xc0 | val >> 6;
		x[1] = 0x80 | val & 0x3f;
		return cast(char[])x.dup;
	}
	else if(val <= 0xd7ff || (val >= 0xe000 && val <= 0xffff)) {
		ubyte[3] x;
		x[0] = 0xe0 | val >> 12;
		x[1] = 0x80 | val >> 6 & 0x3f;
		x[2] = 0x80 | val & 0x3f;
		return cast(char[])x.dup;
	}
	else if(val < 0x10ffff) {
		ubyte[4] x;
		x[0] = 0xf0 | val >> 18;
		x[1] = 0x80 | val >> 18 & 0x3f;
		x[2] = 0x80 | val >> 6 & 0x3f;
		x[3] = 0x80 | val & 0x3f;
		return cast(char[])x.dup;
	}
	else return null;
}

Ch[] fromDecimalToCh(Ch)(uint val)
{
	char[] res = fromDecimalToUtf8(val);
	static if(is(Ch == char))
		return res;
	else static if(is(Ch == wchar))
		return Unicode.toUtf16(res);
	else static if(is(Ch == dchar))
		return Unicode.toUtf32(res);
	else assert(false, "Unsupported character type " ~ Ch.stringof ~ " while doing numeric reference (&#nn;) decoding");
}