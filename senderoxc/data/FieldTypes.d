module senderoxc.data.FieldTypes;

public import dbi.BindType;

struct FieldType
{
	char[] type;
	char[] DType;
	BindType bindType;
	uint limit;
}

const static FieldType[] FieldTypes =
	[
	 FieldType("Bool","bool", BindType.Bool),
	 FieldType("UByte","ubyte", BindType.UByte),
	 FieldType("Byte","byte", BindType.Byte),
	 FieldType("UShort","ushort", BindType.UShort),
	 FieldType("Short","short", BindType.Short),
	 FieldType("UInt","uint", BindType.UInt),
	 FieldType("Int","int", BindType.Int),
	 FieldType("ULong","ulong", BindType.ULong),
	 FieldType("Long","long", BindType.Long),
	 FieldType("Float","float", BindType.Float),
	 FieldType("Double","double", BindType.Double),
	 FieldType("String","char[]", BindType.String, 255),
	 FieldType("Text","char[]", BindType.String, ushort.max - 1),
	 FieldType("Binary","ubyte[]", BindType.Binary, 255),
	 FieldType("Blob","ubyte[]", BindType.Binary, ushort.max - 1),
	 FieldType("DateTime","DateTime", BindType.DateTime),
	 FieldType("Time","Time", BindType.Time),
	 //FieldType("Date","Date", BindType.Date),
	 //FieldType("TimeOfDay","TimeOfDay", BindType.Date)
	 ];