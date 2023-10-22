# Build using:
# nim c -f -d:release websocket.nim

import asyncdispatch, asynchttpserver, ws

var connections = newSeq[WebSocket]()

proc cb(req: Request) {.async, gcsafe.} =
  if req.url.path == "/ws":
    try:
      var ws = await newWebSocket(req)
      connections.add ws
      await ws.send("Websocket:")
      while ws.readyState == Open:
        let packet = await ws.receiveStrPacket()
        echo "Received packet: "
        echo packet
        for other in connections:
          if other.readyState == Open:
            asyncCheck other.send(packet)
    except WebSocketClosedError:
      echo "Socket closed. "
    except WebSocketProtocolMismatchError:
      echo "Socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
    except WebSocketError:
      echo "Unexpected socket error: ", getCurrentExceptionMsg()
  await req.respond(Http200, "Hello World")

var server = newAsyncHttpServer()
waitFor server.serve(Port(9002), cb)