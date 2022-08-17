import ../common

{.warning[UnusedImport]: off.}

when websocketBackend == "ws":
  when not (compiles do: import pkg/ws):
    {.error: "websocket backend 'ws' not installed".}
  import pkg/ws as pkgws
  export pkgws

  template isClosed*(ws: WebSocket): bool =
    ws.readyState == ReadyState.Closed

  template readData*(ws: WebSocket): untyped =
    ws.receivePacket

  proc extractCloseData*(data: string): tuple[code: int, reason: string] =
    ## A way to get the close code and reason out of the data of a Close opcode.
    var data = data
    result.code =
      if data.len >= 2:
        (data[0].int shl 8) or data[1].int
      else:
        0
    result.reason = if data.len > 2: data[2..^1] else: ""
elif websocketBackend == "websocket":
  import websocket, asyncnet
  export websocket except close

  type WebSocket* = AsyncWebSocket

  template newWebSocket*(args: varargs[untyped]): untyped =
    newAsyncWebsocketClient(args)

  template send*(ws: WebSocket, text: string): untyped =
    ws.sendText(text)

  template isClosed*(ws: WebSocket): bool =
    bind isClosed
    asyncnet.isClosed(ws.sock)
  
  template close*(ws: WebSocket) =
    discard websocket.close(ws)
elif websocketBackend == "jswebsockets":
  {.error: "jswebsockets not yet supported".}
else:
  {.error: "unknown websocket backend " & websocketBackend.}
