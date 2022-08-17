import ../common

{.warning[UnusedImport]: off.}

when jsonBackend == "json":
  when not (compiles do: import json):
    {.error: "json backend 'json' not installed".}
  import json
  export json
elif jsonBackend == "packedjson":
  when not (compiles do: import packedjson):
    {.error: "json backend 'packedjson' not installed".}
  import packedjson
  export packedjson
elif jsonBackend == "jsony":
  {.error: "jsony not yet supported".}
else:
  {.error: "unknown json backend " & jsonBackend.}
