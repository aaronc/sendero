
module sendero.server.AsyncReader;

import tango.core.Thread;
import tango.net.ServerSocket;
import tango.io.Selector;
import tango.io.selector.model.ISelector;
import sendero.util.WorkQueue;
import sendero.util.ChainBuffer; 

const unsigned ReadEvent = Event.Read | Event.Error | Event.Hangup;
typedef void function(ChainBuffer) ValidatorFunc;
class AsyncReader
{
  private Thread thread;
  private Selector selector;
  private WorkQueue!(SocketConduit) inq;
  private WorkQueue!(SocketConduit) outq;
  private bool running; 
  private ChainBuffer[SocketConduit] active;
  ChainBuffer[uint] requests;

  this(WorkQueue!(SocketConduit) oq, 
       WorkQueue!(SocketConduit) iq,
       ChainBuffer[uint] reqs)
  {
    outq = oq;
    inq = iq;
    requests reqs;
    selector = new Selector();
    thread = new Thread(&run);
  }

  void run()
  {
    selector.open();
    while(running)
    {
      SocketConduit sock;
      while((sock = inq.tryPopFront()) != null)
      {
        selector.register(sock, ReadEvent); 
      }

      int eventCount = selector.select(0.3);
      if (eventCount > 0)
      {
        ISelectionSet selset = selector.selectedSet();

        foreach (SelectionKey key; selset)
        {
          if ((key.events & Event.Hangup == Event.Hangup) 
            ||(key.events & Event.Error == Event.Error))
          {
            //there is an error or hangup, unregister socket
            killSocket(key.conduit());
          }
          else if (key.isReadable())
          {
            handle_data(key.conduit());
          }
        }
      }
    }
  }
  
  void killSocket(SocketConduit cond)
  {
    //there is an error or hangup, unregister socket
    selector.unregister(key.conduit());
    key.conduit().shutdown();
    key.conduit().detach();
  }

  void handle_data(SocketConduit cond)
  {
    ChainBuffer buf = (cond.fileHandle() in active);
    bool reg = false;
    if (buf == null)
    {
      buf = ChainBuffer.New();
    }
    else
      reg = true;
    
    int len = buf.fillAll(cond);
    switch(len)
    {
      case -2:  // bad socket, unregister
        if (reg)
          active.remove(cond.fileHandle());
        killSocket(cond);
        return;
      break;
      case -1: // no data, not an error, but shouldn't ever happen
        return;
      break;
      default:
      ;
    }
    switch (validate(buf))
    {
      case Validator.COMPLETE:
        //send the buf to the processor and unreg from the AA
        outq.pushBack(buf);
        if (reg)
          active.remove(cond.fileHandle());
        break;
      case Validator.INCOMPLETE:
        //save for later
        if (!reg)
          active[cond.fileHandle()] = buf;
        break;
      case Validator.INVALID:
        //might as well get rid of this, no saving it
        ChainBuffer.Delete(buf);
        if (reg)
          active.remove(cond.fileHandle());
      default:
        ;
    }
  }
}
