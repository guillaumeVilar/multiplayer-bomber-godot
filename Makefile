.PHONY: export-linux export-server-linux export-client-linux run-client-linux run-server-linux docker-client-build docker-client-run docker-client-rm docker-client-update docker-server-build docker-server-run docker-server-rm docker-server-update export-client-html export-all-for-gcp

# ========================== LOCAL CLIENT SECTION (no docker) =========================
export-linux:
	godot --path $(shell pwd) --export "Linux/X11" $(shell pwd)/builds/bomber_linux_export.x86_64

export-client-html:
	godot --path $(shell pwd) --export "HTML5" $(shell pwd)/builds/client-html/index.html

run-server-linux: 
	$(shell pwd)/builds/bomber_linux_export.x86_64 --server

run-client-linux: 
	$(shell pwd)/builds/bomber_linux_export.x86_64


export-server-linux: export-linux run-server-linux

export-client-linux: export-linux run-client-linux

launch-godot:
	godot project.godot

export-all-for-gcp: export-client-html export-linux

# ========================== CLIENT HTML DOCKER SECTION =========================
docker-client-build: ## Build client container
	godot --path $(shell pwd) --export "HTML5" $(shell pwd)/builds/client-html/index.html
	docker build -f builds/Dockerfile-client -t godot-client .

docker-client-run: ## Run client container
	docker run --name=godot-client --restart unless-stopped --network host --volume "$(shell pwd)/logs:/tmp/logs" -d -t godot-client
	xdg-open http://127.0.0.1

docker-client-rm:
	docker container stop godot-client
	docker container rm godot-client
	docker image rm godot-client

docker-client-update: docker-client-rm docker-client-build docker-client-run

# =========================== SERVER DOCKER SECTION =========================
docker-server-build:
	godot --path $(shell pwd) --export "Linux/X11" $(shell pwd)/builds/bomber_linux_export.x86_64
	docker build -f builds/Dockerfile-server -t godot-server . 

docker-server-run:
	docker run --name=godot-server --restart unless-stopped -p 10567:10567/tcp -d -t godot-server

docker-server-rm:
	docker container stop godot-server
	docker container rm godot-server
	docker image rm godot-server

docker-server-update: docker-server-rm docker-server-build docker-server-run

# =========================== GCP SECTION ===========================
gcp-trigger-build:
	gcloud builds submit --config builds/cloudbuild.yaml
