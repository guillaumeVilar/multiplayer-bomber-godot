.PHONY: export-client-linux
export-client-linux: 
	godot --path $(shell pwd) --export "Linux/X11" $(shell pwd)/builds/bomber_linux_export.x86_64
	$(shell pwd)/builds/bomber_linux_export.x86_64

run-client-linux: 
	$(shell pwd)/builds/bomber_linux_export.x86_64
