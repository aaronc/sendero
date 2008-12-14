module sendero.server.provider.WorkerPoolTcpServiceProvider;

import sendero.server.model.ITcpServiceProvider;
import sendero.server.WorkerPool;

class WorkerPoolTcpServiceProvider : ITcpServiceProvider
{
	this(ITcpServiceProvider wrappedProvider)
	{
		wrappedProvider_ = wrappedProvider;
		workerPool_ = new WorkerPool;
		workerPool_.start();
	}
	private ITcpServiceProvider wrappedProvider_;
	private WorkerPool workerPool_;
	
	ITcpRequestHandler getRequestHandler()
	{
		return new WorkerPoolTcpRequestHandler(this, wrappedProvider_.getRequestHandler);
	}
	
	void cleanup(ITcpRequestHandler handler)
	{
		auto wrapper = cast(WorkerPoolTcpRequestHandler)handler;
		debug assert(wrapper);
		wrappedProvider_.cleanup(wrapper.wrappedHandler_);
	}
}

class WorkerPoolTcpRequestHandler : ITcpRequestHandler
{
	this(WorkerPoolTcpServiceProvider provider, ITcpRequestHandler wrappedHandler)
	{
		debug assert(provider !is null);
		debug assert(wrappedHandler !is null);
		provider_ = provider;
		wrappedHandler_ = wrappedHandler;
	}
	private ITcpRequestHandler wrappedHandler_;
	private WorkerPoolTcpServiceProvider provider_;

	SyncTcpResponse handleRequest(void[][] data, ITcpCompletionPort completionPort)
	{
		void jobFunc()
		{
			auto data = wrappedHandler_.handleRequest(data, completionPort);
			if(data !is null) {
				completionPort.sendResponseData(data.data);
				completionPort.endResponse(data.keepAlive);
			}
		}
	
		provider_.workerPool_.pushJob(&jobFunc);
		return null;
	}
}