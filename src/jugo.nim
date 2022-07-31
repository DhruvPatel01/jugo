import parseopt
import strutils

import convert

proc main() = 
    var filename: string

    for kind, key, val in getOpt():
        case kind
        of cmdArgument:
            filename = key
        else:
            discard
    
    if filename == "":
        quit("Filename is required")

    let res = convert.to_markdown(filename)
    echo res.join("\n")


when isMainModule:
    main()
