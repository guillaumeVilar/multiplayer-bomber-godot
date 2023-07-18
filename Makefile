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

# =========================== SERVER DOCKER SECTION =========================
docker-build-server:
	docker build -f builds/Dockerfile-server -t godot-server . 

docker-run-server:
	docker run --name=godot-server --restart unless-stopped -p 10567:10567/udp -d -t godot-server

docker-rm-server:
	docker container stop godot-server
	docker container rm godot-server
	docker image rm godot-server

# =========================== GCP SECTION ===========================
gcp-trigger-build:
	gcloud builds submit --config builds/cloudbuild.yaml