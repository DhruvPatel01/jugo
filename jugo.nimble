# Package

version       = "0.1.0"
author        = "Dhruv Patel"
description   = "A package to convert Jupyter notebooks into goldmark supported Hugo blogs."
license       = "MIT"
srcDir        = "src"
bin           = @["jugo"]


# Dependencies

requires "nim >= 2.0.0"
requires "regex >= 0.26.0"
requires "checksums "
