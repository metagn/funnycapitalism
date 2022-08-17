{.warning[UnusedImport]: off.}

when not (compiles do: import etf):
  {.error: "package etf not installed for optional etf support".}

import etf
export etf
