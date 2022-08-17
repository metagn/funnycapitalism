# Package

version       = "0.1.0"
author        = "metagn"
description   = "barebones discord library"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.4"
# optional ws backend, set with -d:discordWebsocketBackend
when false:
  requires "ws"
  requires "websocket"
# optional json backend, set with -d:discordJsonBackend
when false:
  requires "packedjson"
# optional zip backend, set with -d:discordZipBackend
when false:
  requires "zip"
  requires "zippy"
# optional etf support
when false:
  requires "etf"
