import uri

const 
  jsonBackend* = (
    const discordJsonBackend {.strdefine.} = "json";
    discordJsonBackend
  )
    ## JSON library backend. Can be "json" or "packedjson".
    ## Set with `-d:discordJsonBackend=...`
  websocketBackend* = (
    const discordWebsocketBackend {.strdefine.} = "ws";
    discordWebsocketBackend
  )
    ## Websocket library backend. Can be "ws" or "websocket".
    ## Set with `-d:discordWebsocketBackend=...`
  zipBackend* = (
    const discordZipBackend {.strdefine.} = "none";
    discordZipBackend
  )
    ## Zip (decompression) library backend. Can be "none" for no compression, "zip" or "zippy".
    ## Set with `-d:discordZipBackend=...`
  useEtf* = (
    const discordEtf {.booldefine.} = false;
    discordEtf
  )
    ## Whether or not to use ETF. Requires use of etf package.
    ## Set with -d:discordEtf
  discordTrace* {.booldefine.} = false
    ## Optional trace logs

const
  discordUserAgent* {.strdefine.} = "funnycapitalism (1.0 https://github.com/metagn/funnycapitalism)"
  discordGatewayVersion* {.intdefine.} = 9
  api* = ("https://discordapp.com/api/v" & $discordGatewayVersion & "/").parseUri()

type
  Intent* = enum
    intentGuilds
    intentGuildMembers
    intentGuildBans
    intentGuildEmojisAndStickers
    intentGuildIntegrations
    intentGuildWebhooks
    intentGuildInvites
    intentGuildVoiceStates
    intentGuildPresences
    intentGuildMessages
    intentGuildMessageReactions
    intentGuildMessageTyping
    intentDirectMessages
    intentDirectMessageReactions
    intentDirectMessageTyping
    intentGuildScheduledEvents
  
  Intents* = set[Intent]

proc raw*(intents: Intents): int32 =
  for i in intents:
    result = result or (1i32 shl i.int)
