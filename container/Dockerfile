# TODO: Add git clone of keg-deploy here with the GIT_KEY env
# Use the FROM directive to load the git key here, as an arg
# Then copy into the $KEG_BASE_IMAGE image
# This way the git key is secure, and we can get a new copy of the keg-deploy repo

# Define the image args before the FROM directive
# Allows overwriting them if needed
ARG KEG_BASE_IMAGE=docker.io/library/node:14.16.0-alpine
FROM $KEG_BASE_IMAGE as keg-alpine

WORKDIR /temp

# Ensure the app root directory
ARG DOC_APP_PATH=/keg/app
ENV DOC_APP_PATH=$DOC_APP_PATH

# Set the versions for awc-cli and terraform
ARG AWS_CLI_VERSION=1.16.278
ENV AWS_CLI_VERSION=$AWS_CLI_VERSION
ARG TF_CLI_VERSION=0.12.28
ENV TF_CLI_VERSION=$TF_CLI_VERSION

# Terraform release url for downloading terraform
ARG TF_RELEASE_URL=https://releases.hashicorp.com/terraform
ENV TF_RELEASE_URL=$TF_RELEASE_URL

# Set the name of terraform package to be downloaded
ARG TF_PACKAGE=terraform_${TF_CLI_VERSION}_linux_amd64.zip
ENV TF_PACKAGE=$TF_PACKAGE

# Copy over the the repo from the host machine
ARG KEG_COPY_LOCAL

ARG GIT_APP_URL=https://github.com/simpleviewinc/keg-deploy.git
ENV GIT_APP_URL=$GIT_APP_URL
ARG GIT_APP_BRANCH=master
ENV GIT_APP_BRANCH=$GIT_APP_BRANCH

# Download terrafrom based on the passed in version
ADD $TF_RELEASE_URL/$TF_CLI_VERSION/$TF_PACKAGE ./
ADD $TF_RELEASE_URL/$TF_CLI_VERSION/terraform_${TF_CLI_VERSION}_SHA256SUMS ./

# Update an add required modules
# Use python (pip) to install the aws-CLI and install it
# Then setup and install terraform
RUN apk -v --update add git groff bash wget python py-pip nano \
    python-dev less mailcap openssh-client; \
    rm /var/cache/apk/*; \
    pip install --upgrade awscli==$AWS_CLI_VERSION --target /usr/local/lib/awscli \
    && printf '#!/bin/sh\nPYTHONPATH=/usr/local/lib/awscli /usr/local/lib/awscli/bin/aws "$@"\n' \
    > /usr/local/bin/aws \
    && chmod +x /usr/local/bin/aws; \
    cat terraform_${TF_CLI_VERSION}_SHA256SUMS | grep "$TF_PACKAGE" > terraform_sha; \
    sha256sum -cs terraform_sha; \
    unzip $TF_PACKAGE -d /bin; \
    rm -f $TF_PACKAGE

# Then pull down the app locally if a git tap url exists
# Otherwise copy over the local version from keg-temp
COPY . /keg-temp/
RUN if [ -z "$KEG_COPY_LOCAL" ] && [ "$GIT_APP_URL" ]; then \
      git clone $GIT_APP_URL $DOC_APP_PATH; \
    fi; \
    if [ ! -d "$DOC_APP_PATH" ]; then \
      cp -R /keg-temp/ $DOC_APP_PATH; \
    fi; \
    rm -rf /keg-temp; \
    cd $DOC_APP_PATH; \
    cp -r $DOC_APP_PATH/mounted/. /keg/mounted/; \
    cp -r $DOC_APP_PATH/terraform/. /keg/terraform/; \
    yarn install --ignore-engines; \
    yarn cache clean; \
    echo "#!/bin/bash" >> /root/.bashrc; \
    echo "" >> /root/.bashrc; \
    echo "[ -f \"/keg/app/container/run.sh\" ] && source /keg/app/container/run.sh" >> /root/.bashrc

# Set the working directory to the app path
WORKDIR $DOC_APP_PATH

# Run the start script
CMD [ "/bin/bash" ]