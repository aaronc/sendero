module sendero.util.Hash;

uint hash (char[] data) {
	uint hash = data.length; uint tmp;
	auto len = data.length;
	int rem;

    if(!hash) return 0;

    rem = len & 3;
    len >>= 2;
    
    auto ptr = data.ptr;

    /* Main loop */
    for (;len > 0; len--) {
        hash  += *cast(ushort*)ptr;
        tmp    = (*cast(ushort*)(ptr+2) << 11) ^ hash;
        hash   = (hash << 16) ^ tmp;
        ptr  += 2*ushort.sizeof;
        hash  += hash >> 11;
    }

    /* Handle end cases */
    switch (rem) {
        case 3: hash += *cast(ushort*)(ptr);
                hash ^= hash << 16;
                hash ^= ptr[ushort.sizeof] << 18;
                hash += hash >> 11;
                break;
        case 2: hash += *cast(ushort*)(ptr);
                hash ^= hash << 11;
                hash += hash >> 17;
                break;
        case 1: hash += *ptr;
                hash ^= hash << 10;
                hash += hash >> 1;
                break;
        default:
        	break;
    }

    /* Force "avalanching" of final 127 bits */
    hash ^= hash << 3;
    hash += hash >> 5;
    hash ^= hash << 4;
    hash += hash >> 17;
    hash ^= hash << 25;
    hash += hash >> 6;

    return hash;
}

unittest
{
	/*
	 * Expected test values were determined using Paul Hseih's
	 * original C code at http://www.azillionmonkeys.com/qed/hash.html
	 */
	
	assert(hash("hello") == 2963130491);
	assert(hash("you") == 614819596);
	assert(hash("me") == 4212997144);
	assert(hash("axd27&gv&23gsdfi") == 573943575);
	assert(hash("zebras-And-bicycles") == 996814927);
	
}
