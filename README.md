# FFV2 container: portable image and on-demand use cases

Build and run the FFV2 R package in a Rocky Linux 9 container. The image is built with Podman and exported as an **Apptainer SIF** for portability; run the SIF with `apptainer run` (or `singularity run`). You can run specific use cases via a wrapper or override the installed package with modified R source for ad-hoc runs.

## Build and test

```bash
make build    # build image met:<TAG> (Podman)
make test     # verify FFV2 loads
make sif      # build SIF met-<TAG>.sif for running with Apptainer
```

Copy the `.sif` file to the machine(s) where you want to run; no container runtime other than Apptainer is required there.

## Copying the image to another machine

**Apptainer/Singularity (SIF)**  
- On the build host: `make sif` (produces `met-<TAG>.sif`).  
- Copy the `.sif` file to the target machine. Run with: `apptainer run met-<TAG>.sif ...` (or `singularity run ...`).

**OCI (Podman/Docker)**  
- On the build host: `make export` (writes `met-<TAG>.tar`).  
- Copy the `.tar` to the target, then: `podman load -i met-<TAG>.tar` (or `docker load -i ...`).

**Check after copy**  
Verify FFV2 loads with the SIF:

```bash
apptainer exec met-<TAG>.sif R -e "library(FFV2); cat('FFV2 loaded successfully\n')"
```

(With Podman-loaded image: `podman run --rm --entrypoint R localhost/met:<TAG> -e "library(FFV2); cat('FFV2 loaded successfully\n')"`.)

## Running a use case (on-demand)

The image entrypoint is a wrapper that runs one of three demo scripts by name. Bind-mount a **workspace** directory that contains your namelists (and, as per namelist, input/output paths). Use Apptainer’s `-B` to bind host paths into the container.

**Usage:**

```bash
apptainer run -B /path/to/workspace:/workspace met-<TAG>.sif <use_case> <args...>
```

**Use cases and arguments:**

| Use case           | Arguments (after use case)              |
|--------------------|-----------------------------------------|
| `scores_by_date`   | namelist obsSys fcstSys mc.cores        |
| `aggregate`        | namelist obsSys fcstSys mc.cores        |
| `scores_by_station`| namelist obsSys fcstSys veriType mc.cores |

**Examples** (replace `<TAG>` with your build tag, e.g. `20250310-1200`):

```bash
# Scores by date (SYNOP DET, 6 cores)
apptainer run -B /host/workspace:/workspace met-<TAG>.sif scores_by_date /workspace/namelist_verSYNOP.nl SYNOP DET 6

# Aggregate
apptainer run -B /host/workspace:/workspace met-<TAG>.sif aggregate /workspace/namelist_verSYNOP.nl SYNOP DET 6

# Scores by station (CONT, 6 cores)
apptainer run -B /host/workspace:/workspace met-<TAG>.sif scores_by_station /workspace/namelist.nl SYNOP DET CONT 6
```

To see wrapper usage (and use-case names) without running a job:

```bash
apptainer run met-<TAG>.sif
```

## Odd runs with modified R source (R CMD INSTALL)

To use **edited** FFV2 code without rebuilding the image:

1. On the host, put the FFV2 **source** tree (e.g. `FFV2-main` with `DESCRIPTION`, `R/`, etc.) in a directory.
2. Bind that directory at the fixed path **`/mnt/FFV2`** in the container.
3. The wrapper will detect `/mnt/FFV2` and run `R CMD INSTALL /mnt/FFV2` before invoking the demo, so the modified package is used for that run.

**Example:**

```bash
apptainer run \
  -B /host/workspace:/workspace \
  -B /host/path/to/FFV2-main:/mnt/FFV2 \
  met-<TAG>.sif scores_by_date /workspace/namelist.nl SYNOP DET 6
```

You can also install manually and then run the wrapper (e.g. in an interactive shell):

```bash
apptainer shell -B /host/FFV2-main:/mnt/FFV2 -B /host/workspace:/workspace met-<TAG>.sif
# inside container:
R CMD INSTALL /mnt/FFV2
/usr/local/bin/run_ffv2.sh scores_by_date /workspace/namelist.nl SYNOP DET 6
```

## Interactive R shell

To get an R prompt instead of running the wrapper:

```bash
apptainer exec met-<TAG>.sif R
```

## Makefile targets

| Target   | Description |
|----------|--------------|
| `build`  | Build image with Podman (depends on Dockerfile, FFV2-main, run_ffv2.sh). |
| `test`   | Run container to verify FFV2 loads. |
| `sif`    | Build Apptainer SIF `met-<TAG>.sif` (for `apptainer run` on target machines). |
| `export` | Write OCI archive `met-<TAG>.tar` for podman/docker load on another machine. |
