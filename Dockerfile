ARG CI_REGISTRY_IMAGE
ARG TAG
ARG DOCKERFS_TYPE
ARG DOCKERFS_VERSION
FROM ${CI_REGISTRY_IMAGE}/${DOCKERFS_TYPE}:${DOCKERFS_VERSION}${TAG}
LABEL maintainer="nathalie.casati@chuv.ch"

ARG CARD
ARG CI_REGISTRY
ARG APP_NAME
ARG APP_VERSION

LABEL app_version=$APP_VERSION
LABEL app_tag=$TAG

WORKDIR /apps/${APP_NAME}

# The sed expression is silencing `printmsg` calls with end=\r that are causing
# a lot of logs to be outputted. They don't play well with GitLab (and other CI
# in general).
ARG DEBIAN_FRONTEND=noninteractive
ADD https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py .
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
        ca-certificates \
        dc \
        file \
        libgomp1 \
        libquadmath0 \
        locales \
        python3 && \
    locale-gen en_US.UTF-8 en_GB.UTF-8 && \
    sed -i -E "s/(printmsg\(([^,]+, )?end='(\\\\r)?')/# SILENCE \\1/g" ./fslinstaller.py && \
    python3 ./fslinstaller.py \
        --conda \
        -d /usr/local/fsl \
        -V ${APP_VERSION} \
        --no_self_update \
        --skip_registration && \
    rm -rf /usr/local/fsl/src && \
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
