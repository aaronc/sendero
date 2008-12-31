module senderoxc.data.FieldTypes;

public import dbi.model.BindType;

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

char[] bindTypeToString(BindType type)
{
	switch(type)
	{
	case(BindType.Bool): return "Bool";
	case(BindType.Byte): return "Byte";
	case(BindType.Short): return "Short";
	case(BindType.Int): return "Int";
	case(BindType.Long): return "Long";
	case(BindType.UByte): return "UByte";
	case(BindType.UShort): return "UShort";
	case(BindType.UInt): return "UInt";
	case(BindType.ULong): return "ULong";
	case(BindType.Float): return "Float";
	case(BindType.Double): return "Double";
	case(BindType.String): return "String";
	case(BindType.Binary): return "Binary";
	case(BindType.Time): return "Time";
	case(BindType.DateTime): return "DateTime";
	case(BindType.Null): return "Null";
	default:
		debug assert(false, "Unknown bind type");
		break;
	}
}