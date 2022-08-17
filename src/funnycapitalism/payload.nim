import common

when useEtf:
  import lib/etf
  export etf
  type Payload* = Term
else:
  import lib/jsonwrapper
  export jsonwrapper
  type Payload* = JsonNode
