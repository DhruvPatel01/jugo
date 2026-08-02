import sugar
import strutils

import regex

# The regular expressions are shamelessly 
# copied from nb2hugo project.
# https://github.com/vlunot/nb2hugo/blob/ee224b990b33d93e47eb9ea0810ebbf6ad787d09/nb2hugo/preprocessors/fixlatex.py

proc process(s: string): string =
    result = s.replace(r"\", r"\\")
    result = result.replace(re2"(?<!\\)_", r"\_")


proc escape_math*(cell_text: string): string =
    const single_dollar_latex = re2"(?<![\\\$])\$(?!\$)(.+?)(?<![\\\$])\$(?!\$)"
    result = cell_text.replace(single_dollar_latex, (m, s) => r"$" &  s[m.group(0)] & r"$")
    
    const double_dollar_latex = re2"\$\$(?s)(.+?)\$\$"
    result = result.replace(double_dollar_latex, (m, s) => r"$$" & s[m.group(0)] & r"$$")

    
    
    
