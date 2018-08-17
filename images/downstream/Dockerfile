# Building:
# docker build --no-cache -t vic-downstream-trigger .
# docker tag vic-downstream-trigger gcr.io/eminent-nation-87317/vic-downstream-trigger:1.x
# gcloud auth login
# gcloud docker -- push gcr.io/eminent-nation-87317/vic-downstream-trigger:1.x
# docker tag vic-downstream-trigger wdc-harbor-ci.eng.vmware.com/default-project/vic-downstream-trigger:1.x
# docker login wdc-harbor-ci.eng.vmware.com/default-project
# docker push wdc-harbor-ci.eng.vmware.com/default-project/vic-downstream-trigger:1.x
FROM vmware/photon:2.0

LABEL name="vic-downstream-trigger"
# The version should be increased each time the file is changed
LABEL version="1.4"

RUN set -eux; \
     tdnf distro-sync --refresh -y; \
     tdnf install gzip -y; \
     tdnf install tar -y; \
     tdnf info installed; \
     tdnf clean all

RUN curl -L https://github.com/drone/drone-cli/releases/download/v0.8.5/drone_linux_amd64.tar.gz | tar zx && \
    install drone /usr/bin

RUN echo '#!/bin/bash' >> /usr/bin/trigger
RUN echo 'num=$(drone build ls --format "{{.Number}} {{.Status}}" --event push --branch "$DOWNSTREAM_BRANCH" "$DOWNSTREAM_REPO" | grep -v running | head -n1 | cut -d" " -f1)' >> /usr/bin/trigger
RUN echo 'for i in {1..5}; do drone build start "$DOWNSTREAM_REPO" $num && break || sleep 15; done' >> /usr/bin/trigger
RUN chmod +x /usr/bin/trigger

ENTRYPOINT ["trigger"]
