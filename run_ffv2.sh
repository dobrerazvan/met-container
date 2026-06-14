#!/usr/bin/env bash
# FFV2 use-case wrapper: run demo scripts by name with uniform arguments.
# Usage:
#   run_ffv2.sh scores_by_date    <namelist> <obsSys> <fcstSys> <mc.cores>
#   run_ffv2.sh aggregate         <namelist> <obsSys> <fcstSys> <mc.cores>
#   run_ffv2.sh scores_by_station <namelist> <obsSys> <fcstSys> <veriType> <mc.cores>
# If /mnt/FFV2 exists (mounted FFV2 source), runs R CMD INSTALL /mnt/FFV2 first.

set -e

FFV2_SOURCE_MOUNT="/mnt/FFV2"

# Optional: install from mounted source for ad-hoc runs with modified R code
if [ -d "$FFV2_SOURCE_MOUNT" ] && [ -f "$FFV2_SOURCE_MOUNT/DESCRIPTION" ]; then
    echo "Installing FFV2 from mounted source at $FFV2_SOURCE_MOUNT ..."
    R CMD INSTALL "$FFV2_SOURCE_MOUNT" || { echo "R CMD INSTALL failed."; exit 1; }
    echo "Done."
fi

USE_CASE="${1:-}"
if [ -z "$USE_CASE" ]; then
    echo "Usage: run_ffv2.sh <use_case> [args...]" >&2
    echo "  use_case: scores_by_date | aggregate | scores_by_station" >&2
    echo "  scores_by_date:    namelist obsSys fcstSys mc.cores" >&2
    echo "  aggregate:         namelist obsSys fcstSys mc.cores" >&2
    echo "  scores_by_station: namelist obsSys fcstSys veriType mc.cores" >&2
    exit 1
fi

DEMO_DIR=$(R --vanilla -s -e "cat(system.file('demo', package='FFV2'))")
if [ -z "$DEMO_DIR" ] || [ ! -d "$DEMO_DIR" ]; then
    echo "Could not find FFV2 demo directory. Is FFV2 installed?" >&2
    exit 1
fi

case "$USE_CASE" in
    scores_by_date)
        if [ $# -ne 5 ]; then
            echo "scores_by_date requires: namelist obsSys fcstSys mc.cores" >&2
            exit 1
        fi
        exec Rscript "$DEMO_DIR/starter_scores_by_date.R" "$2" "$3" "$4" "$5"
        ;;
    aggregate)
        if [ $# -ne 5 ]; then
            echo "aggregate requires: namelist obsSys fcstSys mc.cores" >&2
            exit 1
        fi
        exec Rscript "$DEMO_DIR/starter_aggregate.R" "$2" "$3" "$4" "$5"
        ;;
    scores_by_station)
        if [ $# -ne 6 ]; then
            echo "scores_by_station requires: namelist obsSys fcstSys veriType mc.cores" >&2
            exit 1
        fi
        exec Rscript "$DEMO_DIR/starter_scores_by_station.R" "$2" "$3" "$4" "$5" "$6"
        ;;
    *)
        echo "Unknown use_case: $USE_CASE" >&2
        echo "  use_case: scores_by_date | aggregate | scores_by_station" >&2
        exit 1
        ;;
esac
