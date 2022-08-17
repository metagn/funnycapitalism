import macros, messages, macrocache

type Command* = object
  name*, info*: string
  node*: NimNode

proc toNode(c: Command): NimNode {.compileTime.} =
  newTree(nnkPar,
    newLit(c.name),
    newLit(c.info),
    c.node)

proc fromNode(n: NimNode): Command {.compileTime.} =
  Command(
    name: n[0].strVal,
    info: n[1].strVal,
    node: n[2]
  )

const commands* = CacheSeq"discord.commands"

iterator realCommands*(): Command =
  for c in commands:
    yield c.fromNode

macro addCommand*(name: static string, templateSymbol: untyped) =
  var cmd = Command()
  cmd.name = name
  expectKind templateSymbol, nnkSym
  let impl = templateSymbol.getImpl
  expectKind impl, nnkTemplateDef
  cmd.node = templateSymbol
  let body = impl[^1]
  if body.kind == nnkStmtList:
    var infoSet = false
    for c in body:
      if c.kind == nnkCommentStmt:
        if cmd.info.len != 0 and cmd.info[^1] != '\n':
          cmd.info.add("\n")
        cmd.info.add(c.strVal)
      elif not infoSet and c.kind in {nnkCommand, nnkCall, nnkCallStrLit} and
        c.len == 2 and c[0].kind == nnkIdent and c[0].strVal == "info" and
        c[1].kind in {nnkStrLit, nnkRStrLit, nnkTripleStrLit}:
        cmd.info = c[1].strVal
        infoSet = true
  else: discard
  commands.add(toNode(cmd))

macro cmd*(name: untyped, body: untyped) =
  let templateName = genSym(nskTemplate, name.strVal)
  result = newStmtList(
    newProc(
      procType = nnkTemplateDef,
      name = templateName,
      params = [newEmptyNode()],
      body = body,
      pragmas = newTree(nnkPragma, ident"used")),
    newCall(bindSym"addCommand", name, templateName))

import tables

proc nameInfoTable*: Table[string, string] {.compileTime.} =
  result = initTable[string, string](commands.len)
  for i in 0 ..< commands.len:
    let c = commands[i].fromNode
    result[c.name] = (c.info)

macro commandBody*(name: static string): untyped =
  for c in realCommands():
    if c.name == name: return c.node

macro eachCommand*(message: MessageEvent, content, args: string, body: untyped): untyped =
  result = newStmtList()
  for c in realCommands():
    let name = c.name
    let node = c.node
    result.add(quote do:
      block:
        const prefix {.used, inject.} = `name`
        template commandBody: untyped {.used.} =
          let message {.inject, used.} = `message`
          let content {.inject, used.} = `content`
          let args {.inject, used.} = `args`
          `node`
        `body`)
  result = newBlockStmt(result)
