import parseopt
import strutils
import os

import convert

proc isValidNotebook(path: string): bool {.inline.} =
    ".ipynb_checkpoints" notin path and path.endsWith(".ipynb")

proc walk(srcDir, tgtDir: string; stack: var seq[string]) =
    for dir in walkDir(srcDir):
        let
            isDir = dir.kind == pcDir or dir.kind == pcLinkToDir
            dstDir = joinPath(tgtDir, splitFile(dir.path).name)

        if isDir and dir.path in stack:
            continue
        elif isDir:
            stack.add(dir.path)
            walk(dir.path, dstDir, stack)
            discard stack.pop()
        elif dir.path.isValidNotebook:
            let res = convert.to_markdown(dir.path, dstDir)
            if res:
                echo "Converted " & dir.path

proc main() =
    var srcDir, tgtDir: string
    var nargs = 0

    for kind, key, val in getOpt():
        case kind
        of cmdArgument:
            if nargs == 0: srcDir = key
            if nargs == 1: tgtDir = key
            nargs += 1
        else:
            discard

    if srcDir == "" or tgtDir == "":
        quit("Usage: jugo srcDir tgtDir")

    var stack = @[srcDir, ]
    walk(srcDir, tgtDir, stack)




when isMainModule:
    main()
