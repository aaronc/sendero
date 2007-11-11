

module sendero.server.AsyncListener;

import tango.core.Thread;
import tango.net.ServerSocket;
import tango.io.Selector;
import sendero.util.WorkQueue;
import sendero.util.AsyncReader;
import tango.io.selector.model.ISelector;

const uint EvtPersistRead = Event.Read;

class AsyncListener
{
  private Thread thread;
  private Selector selector;
  private AsyncReader reader;
  private listener = ServerSocket;
  private bool running; 

  this(AsyncReader ar)
  {
    reader = ar;
    running = true;
    selector = new Selector();
    thread = new Thread(&run);
  }

  void run()
  {
    listener = new ServerSocket(new InternetAddress(BIND_ADDR, 3456), 128 * 8, true);
    listener.socket().blocking(false);
    running = true;
    selector.open();
    selector.register(listener, EvtPersistRead); 
    event_loop();
    selector.close();
  }

  void event_loop()
  {
    while (running)
    {
      int eventCount = selector.select(0.3);
      if (eventCount > 0)
      {
        ISelectionSet selset = selector.selectedSet();
        foreach (SelectionKey key; selset)
        {
          if (key.check(Event.Error) || key.check(Event.Hangup))
          {
            logger.info(sprint("closing socket {}", key.conduit().fileHandle()));
            selector.unregister(key);
            (cast(SocketConduit)key.conduit()).detach();
          }
        }
        foreach (SelectionKey key; selset)
        {
          if (key.conduit() is listener)
          {
            handle_connection(key.conduit());
          }
        }
      }
    }
  }

  void handle_connection(ISelectable conduit)
  {
    ServerSocket server = cast(ServerSocket) conduit;
    SocketConduit cond = server.accept();

    reader.add(cond);	
  }
}
