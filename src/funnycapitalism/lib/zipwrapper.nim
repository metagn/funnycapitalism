import ../common

{.warning[UnusedImport]: off.}

when zipBackend == "none":
  template uncompress*(x: untyped): untyped = x
elif zipBackend == "zip":
  when not (compiles do: import zip/zlib):
    {.error: "zip backend 'zip' not installed".}
  from zip/zlib import uncompress
  export uncompress
elif zipBackend == "zippy":
  when not (compiles do: import zippy):
    {.error: "zip backend 'zippy' not installed".}
  from zippy import uncompress
  export uncompress
else:
  {.error: "unknown zip backend " & zipBackend.}
