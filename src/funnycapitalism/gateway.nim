import lib/[wswrapper, zipwrapper], asyncdispatch, asyncnet, net, common, tables, payload

when useEtf:
  import lib/etf
  proc send*(ws: WebSocket, data: Term) {.async.} =
    let s = toEtf(data)
    when discordTrace:
      echo "sending " & $data
    await ws.send(s, opcode = Opcode.Binary)
else:
  proc send*(ws: WebSocket, data: JsonNode) {.async.} =
    let s = $data
    when discordTrace:
      echo "sending " & s
    await ws.send(s)

  template send(ws: WebSocket, op: int, data: untyped): auto =
    ws.send(%*{
      "op": op,
      "d": data
    })

proc identify*(ws: WebSocket, token: string, intents: Intents) {.async.} =
  when useEtf:
    asyncCheck ws.send(term({
      binary("op"): term(2u8),
      binary("d"): term({
        binary("token"): binary(token),
        #(Term(tag: tagAtomUtf8, atom: "compress".Atom), Term(tag: tagUint8, u8: compress.byte)),
        binary("large_threshold"): term(250i32),
        binary("intents"): term(intents.raw),
        binary("properties"): term({
          binary("$os"): binary(hostOS),
          binary("$browser"): binary("Nim"),
          binary("$device"): binary("Nim")
        })
      })
    }))
  else:
    asyncCheck ws.send(op = 2, {
      "token": token,
      "compress": zipBackend != "none",
      "large_threshold": 250,
      "intents": intents.raw,
      "properties": {
        "$os": hostOS,
        "$browser": "Nim",
        "$device": "Nim"
      }
    })

proc singleHeartbeat*(ws: WebSocket, lastSeq: int, interval: int) {.async.} =
  when useEtf:
    asyncCheck ws.send(term({
      binary("op"): term(1u8),
      binary("d"): term(lastSeq.int32)
    }))
  else:
    asyncCheck ws.send(op = 1, lastSeq)

when false and declared(Thread):
  from os import sleep
  proc heartbeatThread(arg: tuple[ws: WebSocket, lastSeq: int, interval: int]) {.thread, nimcall.} =
    while not arg.ws.isClosed:
      waitFor singleHeartbeat(arg.ws, arg.lastSeq, arg.interval)
      sleep(arg.interval)
  template heartbeat*(ws: WebSocket, lastSeq: int, interval: int) =
    var thread: Thread[(WebSocket, int, int)]
    createThread(thread, heartbeatThread, (ws, lastSeq, interval))
else:
  proc heartbeatLoop(ws: WebSocket, lastSeq: int, interval: int) {.async.} = 
    while not ws.isClosed:
      await singleHeartbeat(ws, lastSeq, interval)
      await sleepAsync(interval)
  template heartbeat*(ws: WebSocket, lastSeq: int, interval: int) =
    asyncCheck heartbeatLoop(ws, lastSeq, interval)

proc process*[T](dispatcher: T, ws: WebSocket, token: string, intents: Intents, lastSeq: ref int, data: Payload) =
  let op = data["op"].getInt()
  when discordTrace:
    if op != 0: echo "received ", data
  case op
  of 0:
    lastSeq[] = data["s"].getInt()
    let
      d = data["d"]
      t = data["t"].getStr()
    when discordTrace:
      echo "received event ", t
    try:
      dispatcher.dispatch(t, d)
    except Exception as e:
      echo "ignoring exception ", e.name, " with message '", e.msg, "' from dispatch"
      when discordTrace:
        writeStackTrace()
  of 10:
    echo "heartbeating & identifying"
    heartbeat(ws, lastSeq[], data["d"]["heartbeat_interval"].getInt)
    asyncCheck identify(ws, token, intents)
  else: discard

proc read*[T](dispatcher: T, ws: WebSocket, token: string, intents: Intents, lastSeq: ref int) {.async.} =
  while not ws.isClosed:
    let (opcode, data) = await ws.readData()
    case opcode
    of Opcode.Text:
      when useEtf:
        echo "got text: ", data
      else:
        let json = parseJson(data)
        process dispatcher, ws, token, intents, lastSeq, json
    of Opcode.Binary:
      when useEtf:
        let etf = parseEtf(data)
        process dispatcher, ws, token, intents, lastSeq, etf
      else:
        let text = uncompress(data)
        if text.len == 0:
          echo "Decompression failed, ignoring"
        else:
          process dispatcher, ws, token, intents, lastSeq, parseJson(text)
    of Opcode.Close:
      ws.close()
      let closeData = extractCloseData(data)
      when compiles(onClose(dispatcher, closeData.code, closeData.reason, lastSeq)):
        onClose(dispatcher, closeData.code, closeData.reason, lastSeq)
      else:
        echo "closed: ", closeData
    else:
      when discordTrace:
        echo "got opcode ", opcode
      continue
