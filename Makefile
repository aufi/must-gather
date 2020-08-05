IMAGE_REGISTRY ?= quay.io
IMAGE_TAG ?= latest
IMAGE_NAME ?= konveyor/must-gather

build: docker-build docker-push

docker-build:
	docker build -t ${IMAGE_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .

docker-push:
	docker push ${IMAGE_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

.PHONY: build docker-build docker-push
# phony use case? prometheus run -> cleanup reference works even without it

prometheus-run: prometheus-cleanup
	# PROM_DATA_DUMP_DIR="./prom-data" && unpack
	docker run -d \
	  --mount type=bind,source="${PROM_DATA_DUMP_DIR}/tmp/prom-data",target=/etc/prometheus/data \
	  --name mig-metrics-prometheus \
	  --publish 127.0.0.1:9090:9090 \
	  prom/prometheus:v2.6.0 \
	&& echo "Started Prometheus on http://localhost:9090"

prometheus-cleanup:
	docker rm -f mig-metrics-prometheus || true
	# rm tmp data dir
