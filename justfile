set dotenv-load

# Install the Aqago client.
install:
    #!/usr/bin/env bash

    set -euo pipefail
    
    OS=$(uname -s)
    ARCH=$(uname -m)

    rm -rf .bin
    mkdir .bin

    if [[ "$OS" == "Linux" ]]; then
        if [[ "$ARCH" == "x86_64" ]]; then
            TARGET="x86_64-unknown-linux-musl"
        elif [[ "$ARCH" == "aarch64" ]]; then
            TARGET="aarch64-unknown-linux-musl"
        else
            echo "Unknown Linux architecture: $ARCH"
            exit 1
        fi
    elif [[ "$OS" == "Darwin" ]]; then
        if [[ "$ARCH" == "x86_64" ]]; then
            TARGET="x86_64-apple-darwin"
        elif [[ "$ARCH" == "arm64" ]]; then
            TARGET="aarch64-apple-darwin"
        else
            echo "Unknown macOS architecture: $ARCH"
            exit 1
        fi
    else
        echo "Unsupported OS: $OS"
        exit 1
    fi

    BASE_URL="https://aqago-agent-and-cli-binaries-dev.s3.us-east-1.amazonaws.com"

    LATEST_VERSION=$(curl -sfSL "$BASE_URL/latest")
    echo "Latest Aqago Version: ${LATEST_VERSION}"

    DOWNLOAD_URL="$BASE_URL/$LATEST_VERSION/$TARGET.tar.gz"
    echo "downloading 'aqago-cli' from '$DOWNLOAD_URL'"
    curl -sfSL "$DOWNLOAD_URL" | tar -zxvf - -C .bin aqago-cli
    chmod +x .bin/aqago-cli

    # LATEST_VERSION=$(curl -sfSL https://api.github.com/repos/silitics/rugix/releases/latest | jq -r ".tag_name")
    LATEST_VERSION="v0.8.4"
    echo "Latest Rugix Version: ${LATEST_VERSION}"
    DOWNLOAD_URL="https://github.com/silitics/rugix/releases/download/$LATEST_VERSION/$TARGET.tar"
    echo "downloading 'rugix-bundler' from '$DOWNLOAD_URL'"
    curl -sfSL "$DOWNLOAD_URL" | tar -xvf - -C .bin rugix-bundler


# Create a new upload bundle.
build SYSTEM BUNDLE_OPTS="":
    ./run-bakery bake image {{SYSTEM}}
    ./run-bakery bake bundle {{SYSTEM}} {{BUNDLE_OPTS}}


# Push the update bundle as an artifact.
push SYSTEM NAME="rugix-os-bundle" TAG="latest" VARIANT="":
    #!/usr/bin/env bash

    set -euo pipefail

    if [ ! -e .bin/rugix-bundler ]; then
        just install
    fi

    ARTIFACT_NAME="{{NAME}}"
    ARTIFACT_TAG="{{TAG}}"
    ARTIFACT_VARIANT="{{VARIANT}}"

    if [ -z "$ARTIFACT_VARIANT" ]; then
        ARTIFACT_VARIANT="{{SYSTEM}}"
    fi

    echo "ARTIFACT_NAME=${ARTIFACT_NAME}"
    echo "ARTIFACT_TAG=${ARTIFACT_TAG}"
    echo "ARTIFACT_VARIANT=${ARTIFACT_VARIANT}"

    RELEASE_ID=$(jq -r ".release.id" <build/{{SYSTEM}}/system-build-info.json)
    BUNDLE_HASH=$(./.bin/rugix-bundler hash build/{{SYSTEM}}/system.rugixb)

    echo "RELEASE_ID=${RELEASE_ID}"
    echo "BUNDLE_HASH=${BUNDLE_HASH}"

    echo '{ "rugix.release.id": "'$RELEASE_ID'", "rugix.bundle.hash": "'$BUNDLE_HASH'" }' \
        >build/{{SYSTEM}}/aqago-metadata.json

    just cli artifacts create --metadata build/{{SYSTEM}}/aqago-metadata.json \
        --tag "$ARTIFACT_TAG" \
        --variant "$ARTIFACT_VARIANT" \
        "$ARTIFACT_NAME" \
        build/{{SYSTEM}}/system.rugixb

# Create a new application.
create-application NAME="system-ota-manager-rugix":
    just cli applications create {{NAME}} \
        --artifact rugix-os-bundle:latest~efi-arm64 \
        --artifact rugix-os-bundle:latest~efi-amd64 \
        --artifact rugix-os-bundle:latest~pi4 \
        --artifact rugix-os-bundle:latest~pi5


# Add the system manager application to a device.
add-application DEVICE NAME="system-ota-manager-rugix:latest":
    just cli devices add-application {{DEVICE}} {{NAME}}


# Run a local version for testing.
run SYSTEM="efi-arm64":
    ./run-bakery run {{SYSTEM}}


# Configure Aqago Cli for this project.
configure:
    just cli configure --local

# Run the Aqago Cli.
[positional-arguments]
cli *args:
    #!/usr/bin/env bash

    set -euo pipefail

    if [ ! -e .bin/aqago-cli ]; then
        just install
    fi

    ./.bin/aqago-cli "$@"
