module senderoxc.builder.Registry;

import sendero.util.Serialization;
import tango.time.Time;

import tango.util.log.Log;
Logger log;
static this()
{
	log = Log.lookup("senderoxc.builder.Registry");
}

class SenderoXCRegistry
{
	static this()
	{
		try
		{
			if(!loadFromFile!(SenderoXCRegistry)(inst_, "senderoxc_objs/senderoxc.data"))
				inst_ = new SenderoXCRegistry;
			assert(inst_ !is null);
			log.trace("Loaded senderoxc registry");
		}
		catch(Exception ex)
		{
			log.error("Error loading build registry: {}", ex.toString);
		}
	}
	
	static ~this()
	{
		try
		{
			assert(inst_ !is null);
			saveToFile!(SenderoXCRegistry)(inst_, "senderoxc_objs/senderoxc.data");
		}
		catch(Exception ex)
		{
			log.error("Error saving build registry: {}", ex.toString);
		}
	}
	
	private static class Entry
	{
		Time lastModified;
		bool success;
		
		void serialize(Ar)(Ar ar, byte ver)
		{
			ar (success);
			if(ar.loading) {
				long ticks; ar (ticks);
				lastModified = Time(ticks);
			}
			else {
				long ticks = lastModified.ticks;
				ar (ticks) ;
			}
		}
	}
	
	bool success = false;
	
	static void register(char[] modname, Time lastModified, bool success)
	{
		auto pEntry = modname in inst_.entries;
		if(pEntry) {
			pEntry.lastModified = lastModified;
			pEntry.success = success;
		}
		else {
			auto entry = new Entry;
			entry.lastModified = lastModified;
			entry.success = success;
			inst_.entries[modname] = entry;
		}
	}
	
	static bool succeeded(char[] modname)
	{
		auto pEntry = modname in inst_.entries;
		if(pEntry) {
			return pEntry.success;
		}
		else return false;
	}
	
	static Time lastModified(char[] modname)
	{
		auto pEntry = modname in inst_.entries;
		if(pEntry) {
			return pEntry.lastModified;
		}
		else return Time(0);
	}
	
	private static SenderoXCRegistry inst_;
	
	private Entry[char[]] entries;
	
	void serialize(Ar)(Ar ar, byte ver)
	{
		ar (entries) (success);
	}
}