a simple command tries to find all the files recursively.

for each file
	it remembers the relative path
	if the file contains a metadata path replace use that path instead of above path
	using path, generate a md file at that location
	write header into that file
	write jupyter cells into that file


use case
- [] jugo path/to/input.ipynb
    will inline images
- [ ] jugo path/to/input.ipynb path/to/output.md
    will inline images
- [ ] jugo path/to/input.ipynb path/to/dir
    will create a page bundle regard less if it is required or not.
- [ ] jugo path/to/input-dir path/to/output-dir
    will try to find notebooks recusively and create pb regard less if it is required or not.
    

Psudocode
```nim
proc to_hugo(path_to_notebook, path_to_page_bundle: string) -> bool

proc walk(source, target: string; stack: [string]) -> bool = 
	for path in walkDir(source):
		if path is dir and path on stack:
			continue
		elif path is dir:
			stack.add(dir)
			walk(new_source, new_target, stack)
		elif path is file:
			to_hugo(path, generate(path))

```
#TODO:
[x] convert/to_markdown implementation should check the jugo header. If not there skip.
[x] convert/to_markdown should create a leaf node and write files there. existing images should be deleted.
[x] handle outputs
- [x] stream
- [x] display_data, execute_result
[ ] handle attachments