module sendero.server.provider.WorkerPoolTcpServiceProvider;

import sendero.server.model.ITcpServiceProvider;
import sendero.server.WorkerPool;

class WorkerPoolTcpServiceProvider : ITcpServiceProvider
{
	this(ITcpServiceProvider wrappedProvider, WorkerPool workerPool)
	{
		wrappedProvider_ = wrappedProvider;
		workerPool_ = workerPool;
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
	private StagedReadBuffer data_;
	private ITcpCompletionPort completionPort;
	
	private void jobFunc()
	{
			auto res = wrappedHandler_.handleRequest(data_, completionPort);
			if(res !is null) {
				completionPort.sendResponseData(res.data);
				completionPort.endResponse(res.keepAlive);
			}
	}

	SyncTcpResponse handleRequest(StagedReadBuffer data, ITcpCompletionPort completionPort)
	{
		this.data_ = data;
		this.completionPort = completionPort;
		provider_.workerPool_.pushJob(&jobFunc);
		return null;
	}
}