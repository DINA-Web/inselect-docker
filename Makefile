SHELL = /bin/bash
PWD = $(shell pwd)
TAG = dina/inselect:v0

init:
	@curl -L -s -o wait-for-it.sh \
		https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh && \
		chmod +x wait-for-it.sh

	@test -d novnc || \
		git clone --depth=1 https://github.com/kanaka/noVNC.git novnc

build:
	@docker build -t $(TAG) .

debug:
	@docker run -it --rm \
		$(TAG) bash

up:
	@docker run -d --name=inselect \
		-p 8083:8083 \
		-v $(PWD)/data:/root/data \
		$(TAG)

	@wget --retry-connrefused --tries=5 -q --wait=5 --spider \
     		'http://localhost:8083/vnc_auto.html'

	@firefox http://localhost:8083/vnc_auto.html &

clean:
	@docker stop inselect 
	@docker rm -vf inselect

release:
	@docker push $(TAG)
