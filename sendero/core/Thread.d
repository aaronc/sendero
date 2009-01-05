module sendero.core.Thread;

import tango.core.Thread;

class SenderoThread : Thread
{
	private void*[] local_;
	private static TLSKey tlsKey_;
	
	static uint createLocal ();
	static void deleteLocal (uint key);
	static void* getLocal (uint key);
	static void* setLocal (uint key, void* val);
	
	static TLSKey newTlsKey()
	{
	
	}
	
	static TLSKey setTlsKey(TLSKey key)
	{
		
	}
	
	static TLSKey getTlsKey()
	{
	
	}
	
	version( Win32 )
    {
        alias uint TLSKey;
    }
    else version( Posix )
    {
        alias pthread_key_t TLSKey;
    }
	
	static this()
    {
        version( Win32 )
        {
        	tlsKey_ = TlsAlloc();
            assert( tlsKey_ != TLS_OUT_OF_INDEXES );
        }
        else version( Posix )
        {
            int status;

            status = pthread_key_create( &tlsKey_, null );
            assert( status == 0 );
        }
    }
}

class SenderoThreadLocal(T)
{
////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Initializes thread local storage for the indicated value which will be
     * initialized to def for all threads.
     *
     * Params:
     *  def = The default value to return if no value has been explicitly set.
     */
    this( T def = T.init )
    {
        m_def = def;
        m_key = SenderoThread.createLocal();
    }


    ~this()
    {
    	SenderoThread.deleteLocal( m_key );
    }


    ////////////////////////////////////////////////////////////////////////////
    // Accessors
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Gets the value last set by the calling thread, or def if no such value
     * has been set.
     *
     * Returns:
     *  The stored value or def if no value is stored.
     */
    T val()
    {
        Wrap* wrap = cast(Wrap*) SenderoThread.getLocal( m_key );

        return wrap ? wrap.val : m_def;
    }


    /**
     * Copies newval to a location specific to the calling thread, and returns
     * newval.
     *
     * Params:
     *  newval = The value to set.
     *
     * Returns:
     *  The value passed to this function.
     */
    T val( T newval )
    {
        Wrap* wrap = cast(Wrap*) Thread.getLocal( m_key );

        if( wrap is null )
        {
            wrap = new Wrap;
            Thread.setLocal( m_key, wrap );
        }
        wrap.val = newval;
        return newval;
    }


private:
    //
    // A wrapper for the stored data.  This is needed for determining whether
    // set has ever been called for this thread (and therefore whether the
    // default value should be returned) and also to flatten the differences
    // between data that is smaller and larger than (void*).sizeof.  The
    // obvious tradeoff here is an extra per-thread allocation for each
    // ThreadLocal value as compared to calling the Thread routines directly.
    //
    struct Wrap
    {
        T   val;
    }


    T       m_def;
    uint    m_key;
}