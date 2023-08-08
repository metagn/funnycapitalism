{.warning[UnusedImport]: off.}

when not (compiles do: import pkg/etf):
  {.error: "package etf not installed for optional etf support".}

import pkg/etf
export etf
