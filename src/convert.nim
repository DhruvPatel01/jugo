import json
import os
import unicode, strutils
import base64
import strformat
import times
import regex
import md5

import escape_math

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

proc multiline_text(node: JsonNode): string {.inline.} =
    if node == nil:
        return
    if node.kind == JString:
        return node.getStr

    for line in node:
        result.add(line.getStr)
    result.add("\n")

proc read_outputs(outputs: JsonNode): (string, seq[(string, string)]) =
    if outputs == nil: return

    var
        files: seq[(string, string)] = @[]
        out_str = ""

    for output in outputs:
        case output["output_type"].getStr
        of "stream":
            if output["name"].getStr == "stderr": continue
            out_str.add(output["text"].multiline_text)
        of "display_data", "execute_result":
            for k, v in output["data"]:
                case k
                of "text/plain":
                    out_str.add("```text\n" & v.multiline_text & "\n```\n")
                of "image/png":
                    let 
                        file = decode(v.getStr)
                        file_name = file.getMD5 & ".png"
                    files.add((file_name, file))
                    out_str.add(&"![output image for above cell](images/{file_name})\n")

    return (out_str, files)

const image_reg =  re"""!\[[^\]]*\]\((.*)\)"""

proc extract_image(cell, dir: string; attachments: JsonNode): (string, seq[(string, string)]) =
    var
        files: seq[(string, string)] = @[]
        out_str = ""
        lb = 0

    for match in findAll(cell, image_reg):
        let 
            group = match.captures[0]
            bounds = group[0]
            filename = cell[bounds]
       
        if filename.endsWith(".png") or filename.endsWith(".jpg"):
            var file: string
            if filename.startsWith("attachment:"):
                let
                    key = filename.replace("attachment:", "")
                    mime = "image/" & filename.splitPath[1].splitFile[2][1..^1]
                file =attachments[key][mime].getStr.decode
            elif filename.startsWith('.'):
                file = joinPath(dir, filename).readFile
            else:
                file = filename.readFile

            out_str.add(cell[lb ..< bounds.a])
            out_str.add("images/" & filename.splitPath[1])
            files.add((filename.splitPath[1], file))
            lb = bounds.b + 1
    if lb < cell.len:
        out_str.add(cell[lb .. ^1])
    return (out_str, files)
        


proc process_cell(cellNode: JsonNode; dir: string, language = ""): (string, seq[(string, string)]) =
    var
        src = cellNode{"source"}.multiline_text
        out_str = ""
        files: seq[(string, string)] = @[]

    case cellNode["cell_type"].getStr
    of "markdown":
        out_str = src.escape_math()
        let (out_str1, files1) = out_str.extract_image(dir, cellNode{"attachments"})
        out_str = out_str1
        files &= files1
    of "code":
        out_str = "```" & language & "\n" & src & "\n```\n"
        let (output, files1) = cellNode{"outputs"}.read_outputs
        files &= files1
        if output != "": out_str.add(output)
    out_str.add("\n")

    return (out_str, files)

proc toMarkdown*(srcPath, dstDir: string): bool =
    let
        nbformat = parseJson(readFile(srcPath))
        nbinfo = getFileInfo(srcPath)
        metadata = nbformat["metadata"]
        jugo_header = metadata{"jugo"}
        language = get_language(metadata)
        cells = nbformat{"cells"}
        srcDir = srcPath.splitPath[0]

    if jugo_header == nil or cells == nil:
        return false

    var fm: JsonNode
    if jugo_header{"front_matter"} == nil:
        fm = newJObject()
    else:
        fm = jugo_header["front_matter"]

    var
        output: seq[string] = @[]
        files: seq[(string, string)] = @[]
        

    if fm{"title"} == nil:
        fm["title"] = get_title(metadata, srcPath).newJString
    if fm{"date"} == nil:
        fm["date"] = newJString($nbinfo.creationTime.utc)
    if fm{"lastmod"} == nil:
        fm["lastmod"] = newJString($nbinfo.lastWriteTime.utc)

    output.add(pretty(fm))
    output.add("\n")

    for cell_node in cells:
        let (cell_out, cell_files) = process_cell(cell_node, srcDir, language)
        output.add(cell_out)
        files.add(cell_files)

    createDir(dstDir)
    writeFile(joinPath(dstDir, "index.md"), output.join("\n"))

    if files.len > 0:
        let imgDir = joinPath(dstDir, "images")
        removeDir(imgDir)
        createDir(imgDir)
        for (name, file) in files:
            let filePath = joinPath(imgDir, name)
            writeFile(filePath, file)

    return true
