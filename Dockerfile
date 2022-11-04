ARG CI_REGISTRY_IMAGE
ARG DOCKERFS_TYPE
ARG DOCKERFS_VERSION
FROM ${CI_REGISTRY_IMAGE}/${DOCKERFS_TYPE}:${DOCKERFS_VERSION}
LABEL maintainer="nathalie.casati@chuv.ch"

ARG DEBIAN_FRONTEND=noninteractive
ARG CARD
ARG CI_REGISTRY
ARG APP_NAME
ARG APP_VERSION

LABEL app_version=$APP_VERSION

WORKDIR /apps/${APP_NAME}

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \ 
    curl file python locales libquadmath0 && \
    locale-gen en_US.UTF-8 en_GB.UTF-8 && \
    curl -O# https://fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py && \
    if [ ! -z ${CI_REGISTRY} ]; then SILENT="-q"; fi && \
    python fslinstaller.py ${SILENT} -d /usr/local/fsl -V ${APP_VERSION} && \
    /usr/local/fsl/fslpython/envs/fslpython/bin/pip install fsleyes-props==1.7.2 && \
    rm fslinstaller.py && \
    rm -rf /usr/local/fsl/src && \
    apt-get remove -y --purge curl file && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV APP_SPECIAL="terminal"
ENV APP_CMD=""
ENV PROCESS_NAME=""
ENV APP_DATA_DIR_ARRAY=""
ENV DATA_DIR_ARRAY=""
ENV CONFIG_ARRAY=".bash_profile"

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/
COPY ./apps/${APP_NAME}/config config/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
