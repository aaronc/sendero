module sendero.util.ColumnInfo;

enum ColT { Bool, Byte, Short, Int, Long, UByte, UShort, UInt, ULong, Float, Double, VarChar, Text, LongText, Blob, LongBlob, Date, DateTime, TimeStamp, HasOne, HasMany, HABTM, Variant, Object};

class ColumnInfo
{
	ColT type;
	bool notNull;
	bool unique;
	bool primaryKey;
	bool skip = false;
}