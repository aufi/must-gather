IMAGE_REGISTRY ?= quay.io
IMAGE_TAG ?= latest
IMAGE_NAME ?= konveyor/must-gather

PROMETHEUS_LOCAL_DATA_DIR ?= /tmp/mig-prometheus-data-dump
# Search for prom_data.tar.gz archive in must-gather output in currect directory by default
PROMETHEUS_DUMP_PATH ?= $(shell find ./must-gather.local* -name prom_data.tar.gz -printf "%T@ %p\n" | sort -n | tail -1 | cut -d" " -f2)

build: docker-build docker-push

docker-build:
	docker build -t ${IMAGE_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} .

docker-push:
	docker push ${IMAGE_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

.PHONY: build docker-build docker-push

prometheus-run: prometheus-cleanup-container prometheus-load-dump
	docker run -d \
	  --mount type=bind,source=${PROMETHEUS_LOCAL_DATA_DIR},target=/etc/prometheus/data \
	  --name mig-metrics-prometheus \
	  --publish 127.0.0.1:9090:9090 \
	  prom/prometheus:v2.6.0 \
	&& echo "Started Prometheus on http://localhost:9090"

prometheus-load-dump: prometheus-check-archive-file prometheus-cleanup-data
	mkdir -p ${PROMETHEUS_LOCAL_DATA_DIR}
	tar xvf ${PROMETHEUS_DUMP_PATH} -C ${PROMETHEUS_LOCAL_DATA_DIR} --strip-components=1 --no-same-owner
	chmod 777 -R ${PROMETHEUS_LOCAL_DATA_DIR}

prometheus-cleanup-container:
	# delete data files directly from the container to allow delete data directory from outside of the container
	docker exec mig-metrics-prometheus rm -rf /prometheus || true
	docker rm -f mig-metrics-prometheus || true

prometheus-cleanup-data:
	rm -rf ${PROMETHEUS_LOCAL_DATA_DIR}

prometheus-cleanup: prometheus-cleanup-container prometheus-cleanup-data

prometheus-check-archive-file:
	test -f "${PROMETHEUS_DUMP_PATH}" || (echo "Error: Prometheus archive file does not exist. Specify valid file in PROMETHEUS_DUMP_PATH environment variable."; exit 1)
