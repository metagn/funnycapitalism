import funnycapitalism/[lib/wswrapper, common, http, gateway, payload], asyncdispatch, json, httpclient, uri, strformat

when (NimMajor, NimMinor) >= (1, 6):
  type Dispatcher* = concept
    # also supported: proc onClose(d: Self, closeCode: int, closeReason: string, lastSeq: ref int)
    proc dispatch(d: Self, event: string, node: Payload)
else:
  type Dispatcher* = auto

proc fetchGateway*(http: AsyncHttpClient): string =
  let x = http.get(api / "gateway")["url"].getStr()
  result = x & ":443/?encoding=" & (if useEtf: "etf" else: "json") & "&v=" & $gatewayVersion

proc init*[T: Dispatcher](
    dispatcher: T,
    token: string,
    intents: Intents,
    tokenHeaders: var HttpHeaders,
    ws: var WebSocket,
    lastSeq: ref int = new(int)) =
  tokenHeaders = newHttpHeaders({"Authorization": "Bot " & token})
  let gateway = fetchGateway(newHttp(tokenHeaders))
  ws = waitFor newWebSocket(gateway)
  asyncCheck read(dispatcher, ws, token, intents, lastSeq)
