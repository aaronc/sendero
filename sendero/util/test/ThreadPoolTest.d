/**
 * Copyright: Copyright (C) 2007 Rick Richardson.  All rights reserved.
 * License:   BSD Style
 * Authors:   Rick Richardson
 */


module ThreadPoolTest;

import tango.io.Console;
import tango.io.Stdout;
import sendero.util.ThreadPool;
import tango.core.Thread;
import tango.math.Random;

import tango.util.log.Log;
import tango.util.log.Configurator;
import tango.text.convert.Sprint;

Logger logger;
typedef int function(int) Func;

int test_func(int tsk)
{
	auto sprint = new Sprint!(char);
	auto r = new Random();
	r.seed();
	uint u = (r.next() % 10000) + 10000;
	logger.info(sprint("u = {}", u));
	double num = (cast(double) u) / cast(double) 10000.0;

	logger.info(sprint("Starting test_func {}, sleeping for {} seconds", tsk, num));
	Thread.sleep(num);
	logger.info(sprint("test_func {} complete", tsk));
  return 0;
}

class TestFunctor : WQFunctor
{
	this(Func f, int x) {arg1 = x; myFunc = f;}
	void opCall() { result = myFunc(arg1);}
	int arg1;
	int result;
	Func myFunc;
}

void main()
{
	auto sprint = new Sprint!(char);
	logger = Log.getLogger("ThreadPoolTest");

	ThreadPool p = new ThreadPool(100);
  logger.info("done creating new threadpool");
  for(int i = 0; i < 800; ++i)
	{
		logger.info(sprint("adding task {}", i));
		p.add_task(new TestFunctor(&test_func, i));
	}
}

