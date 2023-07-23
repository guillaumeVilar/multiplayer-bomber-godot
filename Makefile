.PHONY: export-linux export-server-linux export-client-linux run-client-linux run-server-linux docker-build-html-client docker-run-html-client docker-rm-client

# ========================== LOCAL CLIENT SECTION (no docker) =========================
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

# ========================== CLIENT HTML DOCKER SECTION =========================
docker-build-html-client: ## Build client container
	godot --path $(shell pwd) --export "HTML5" $(shell pwd)/builds/client-html/index.html
	docker build -f builds/Dockerfile-client -t godot-client .

docker-run-html-client: ## Run client container
	docker run --name=godot-client --restart unless-stopped --network host --volume "$(shell pwd)/logs:/tmp/logs" -d -t godot-client
	xdg-open http://127.0.0.1

docker-rm-client:
	docker container stop godot-client
	docker container rm godot-client
	docker image rm godot-client


# =========================== SERVER DOCKER SECTION =========================
docker-build-server:
	godot --path $(shell pwd) --export "Linux/X11" $(shell pwd)/builds/bomber_linux_export.x86_64
	docker build -f builds/Dockerfile-server -t godot-server . 

docker-run-server:
	docker run --name=godot-server --restart unless-stopped -p 10567:10567/tcp -d -t godot-server

docker-rm-server:
	docker container stop godot-server
	docker container rm godot-server
	docker image rm godot-server

# =========================== GCP SECTION ===========================
gcp-trigger-build:
	gcloud builds submit --config builds/cloudbuild.yaml
