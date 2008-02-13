module sendero.util.Singleton;

template Singleton(X)
{
	static X opCall()
	{
		if(inst is null) {
			synchronized
			{
				if(inst is null)
				{
					inst = new X;
				}
			}
		}
		return inst;
	}
	private static X inst;
}