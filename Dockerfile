FROM rockylinux:9 AS base

RUN dnf -y update && \
    dnf -y install epel-release && \
    dnf -y install dnf-plugins-core && \
    dnf config-manager --set-enabled crb && \
    dnf -y install \
        R-core \
        R-core-devel \
        R-java \
        gcc \
        gcc-c++ \
        gcc-gfortran \
        make \
        cmake \
        libcurl-devel \
        openssl-devel \
        libxml2-devel \
        # sf dependencies
        gdal-devel \
        geos-devel \
        proj-devel \
        sqlite-devel \
        udunits2-devel \
        # RNetCDF dependencies
        netcdf-devel \
        # qs dependencies
        libzstd-devel \
        lz4-devel \
    && dnf clean all

ARG NCPUS=8

ENV MAKEFLAGS="-j${NCPUS}"

RUN R -e " \
    pkgs <- c( \
        'sp', \
        'sf', \
        'data.table', \
        'SpecsVerification', \
        'matrixStats', \
        'RNetCDF', \
        'stringr', \
        'survival', \
        'verification', \
        'reshape2', \
        'pcaPP', \
        'scoringRules', \
        'BH', \
        'RApiSerialize', \
        'stringfish' \
    ); \
    install.packages(pkgs, repos = 'https://cloud.r-project.org', Ncpus = ${NCPUS}); \
    failed <- pkgs[!pkgs %in% installed.packages()[,'Package']]; \
    if (length(failed) > 0) { \
        cat('Failed to install:', paste(failed, collapse=', '), '\n'); \
        quit(status = 1) \
    } \
"

RUN R -e "install.packages( \
    'https://cran.r-project.org/src/contrib/Archive/qs/qs_0.27.3.tar.gz', \
    repos = NULL, type = 'source')"

FROM base AS ffv2

# Fixed path for mounting FFV2 source for ad-hoc runs (R CMD INSTALL /mnt/FFV2)
RUN mkdir -p /mnt/FFV2

COPY FFV2-main /tmp/FFV2
RUN R CMD INSTALL /tmp/FFV2 && rm -rf /tmp/FFV2

COPY run_ffv2.sh /usr/local/bin/run_ffv2.sh
RUN chmod +x /usr/local/bin/run_ffv2.sh

ENTRYPOINT ["/usr/local/bin/run_ffv2.sh"]
CMD []
