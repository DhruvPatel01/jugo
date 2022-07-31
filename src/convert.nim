import json
import os
import unicode, strutils

proc get_language(metadata: JsonNode): string = 
    let language_info = metadata{"language_info"}
    if language_info != nil:
        result = language_info["name"].getStr

proc get_title(metadata: JsonNode; filename: string): string = 
    let title_node = metadata{"title"}
    if title_node != nil:
        title_node.getStr 
    else:
        var (_, title, _) = splitFile(filename)
        title.replace('_', ' ').title

proc read_source(cell: JsonNode): string = 
    case cell["source"].kind
    of JArray:
        for line in cell["source"]:
            result.add(line.getStr)
    of JString:
        result.add(cell["source"].getStr)
    else:
        discard
    

proc process_cell(cell_node: JsonNode; language=""): string =
    var src = cell_node.read_source 
    case cell_node["cell_type"].getStr
    of "markdown":
        result = src.replace(r"\", r"\\")
    of "code":
        result = "```" & language & "\n" & src & "\n```"
    else:
        result = ""
    result.add("\n")

proc to_markdown*(filename: string): seq[string] =
    let
        nbformat = parseJson(readFile(filename))
        metadata = nbformat["metadata"]
        language = get_language(metadata)
        title = get_title(metadata, filename)
        cells = nbformat{"cells"}

    if cells == nil:
        return

    result.add("+++")
    result.add("title = \"" & title & "\"")
    result.add("+++\n")

    for cell_node in cells:
        result.add(process_cell(cell_node, language))