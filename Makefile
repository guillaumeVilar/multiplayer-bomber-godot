.PHONY: export-linux export-server-linux export-client-linux run-client-linux run-server-linux

export-linux:
	godot --path $(shell pwd) --export "Linux/X11" $(shell pwd)/builds/bomber_linux_export.x86_64

run-server-linux: 
	$(shell pwd)/builds/bomber_linux_export.x86_64 --server

run-client-linux: 
	$(shell pwd)/builds/bomber_linux_export.x86_64


export-server-linux: export-linux run-server-linux

export-client-linux: export-linux run-client-linux

launch-godot:
	godot project.godot
