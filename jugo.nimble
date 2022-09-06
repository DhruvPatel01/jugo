# Package

version       = "0.1.0"
author        = "Dhruv Patel"
description   = "A package to convert Jupyter notebooks into goldmark supported Hugo blogs."
license       = "MIT"
srcDir        = "src"
bin           = @["jugo"]


# Dependencies

requires "nim >= 1.6.6"
requires "regex >= 0.19.0"
