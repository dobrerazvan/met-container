TAG := $(shell date +%Y%m%d-%H%M)
IMAGE := met:$(TAG)

build: Dockerfile FFV2-source run_ffv2.sh
	podman build -t $(IMAGE) .

test: build
	podman run --rm --entrypoint R $(IMAGE) -e "library(FFV2); cat('FFV2 loaded successfully\n')"

# OCI archive for copying to another machine (podman load / docker load)
export: build
	podman save localhost/$(IMAGE) -o met-$(TAG).tar

sif: export
	apptainer build met-$(TAG).sif docker-archive://met-$(TAG).tar

clean:
	rm -f met-$(TAG).tar

# Run examples (mount workspace with namelists/data; optional: mount FFV2 source at -v HOST_FFV2:/mnt/FFV2 for R CMD INSTALL)
# podman run --rm -v /host/workspace:/workspace $(IMAGE) scores_by_date /workspace/namelist.nl SYNOP DET 6
# podman run --rm -v /host/workspace:/workspace $(IMAGE) aggregate /workspace/namelist.nl SYNOP DET 6
# podman run --rm -v /host/workspace:/workspace $(IMAGE) scores_by_station /workspace/namelist.nl SYNOP DET CONT 6
