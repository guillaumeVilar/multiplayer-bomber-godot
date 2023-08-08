.PHONY: export-linux export-server-linux export-client-linux run-client-linux run-server-linux docker-client-build docker-client-run docker-client-rm docker-client-update docker-server-build docker-server-run docker-server-rm docker-server-update export-client-html export-all-for-gcp

# ========================== LOCAL CLIENT SECTION (no docker) =========================
export-linux:
	../Godot_v4.1.1-stable_linux.x86_64 --path $(shell pwd) --export-release "Linux/X11" $(shell pwd)/builds/bomber_linux_export.x86_64

export-client-html:
	./builds/Godot_v4.1.1-stable_linux.x86_64 --path $(shell pwd) --export "HTML5" $(shell pwd)/builds/client-html/index.html --headless

run-server-linux: 
	$(shell pwd)/builds/bomber_linux_export.x86_64 --server

run-client-linux: 
	$(shell pwd)/builds/bomber_linux_export.x86_64 --local


export-server-linux: export-linux run-server-linux

export-client-linux: export-linux run-client-linux

export-then-run-server-client: export-linux
	konsole --noclose  -e $(shell pwd)/builds/bomber_linux_export.x86_64 --server &
	konsole --noclose  -e $(shell pwd)/builds/bomber_linux_export.x86_64 --local & 
	konsole --noclose  -e $(shell pwd)/builds/bomber_linux_export.x86_64 --local

launch-godot:
	godot project.godot

export-all-for-gcp: export-client-html export-linux

# ========================== CLIENT HTML DOCKER SECTION =========================
## Build client container
docker-client-build: export-client-html
	docker build -f builds/Dockerfile-client -t godot-client .
	docker run --name=godot-client --restart unless-stopped --network host --volume "$(shell pwd)/logs:/tmp/logs" -d -t godot-client
	xdg-open http://127.0.0.1

docker-client-run: ## Run client container
	docker run --name=godot-client --restart unless-stopped --network host --volume "$(shell pwd)/logs:/tmp/logs" -d -t godot-client
	xdg-open http://127.0.0.1

docker-client-rm:
	docker container stop godot-client
	docker container rm godot-client
	docker image rm godot-client

docker-client-update: docker-client-rm docker-client-build-run

# =========================== SERVER DOCKER SECTION =========================
docker-server-build: export-linux
	docker build -f builds/Dockerfile-server -t godot-server .
	docker run --name=godot-server --restart unless-stopped -p 10567:10567/tcp -d -t godot-server

docker-server-run:
	docker run --name=godot-server --restart unless-stopped -p 10567:10567/tcp -d -t godot-server

docker-server-rm:
	docker container stop godot-server
	docker container rm godot-server
	docker image rm godot-server

docker-server-update: docker-server-rm docker-server-build-run

# =========================== GCP SECTION ===========================
gcp-trigger-build:
	gcloud builds submit --config builds/cloudbuild.yaml
