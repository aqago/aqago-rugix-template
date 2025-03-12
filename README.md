# Overview

This project creates a turnkey Debian Bookworm OS image pre-configured with
Aqago + Rugix.

Aqago is developer-friendly software infrastructure for IoT and robotics. Aqago
makes it easy to add production-grade authentication, API security, content
storage, signaling, configuration, logging and monitoring to physical systems at
any development stage, from lab prototypes to globally deployed products at
scale.

Rugix provides robust, secure, fail-safe over the air OS updates to every device
in your fleet.

## Getting started

### System requirements

Install [`just`](https://just.systems/man/en/) on your system if running
locally. If using with the provided GitHub Action, `just` is installed
automatically.

### Adding your Aqago backend credentials

If running locally, run `just configure` and enter your Aqago backend
credentials. This command will create a local configuration file
`.aqago-cli.toml` with your Aqago credentials.

If running via the GitHub Actions workflow, define `AQAGO_MGMT_URL` and
`AQAGO_MGMT_KEY` as environment secrets.

### Adding your Aqago backend URL to the on-device agent

#### Local

If running locally, configure the on-device agent with URLs for your Aqago
backend APIs. To do this, copy the file `config/aqago-agent.template.toml` to
`config/aqago-agent.toml` and replace the configuration placeholders.

#### GitHub Actions workflow

If running via the GitHub Actions workflow, define `AQAGO_MGMT_URL`,
`AQAGO_AGENT_URL`, `AQAGO_DEVICE_URL`, and `AQAGO_BROKER_URL` as environment
secrets. The CI workflow will insert these values into the template
configuration file (`config/aqago-agent.template.toml`).

### Building the image

To build the image, run `just build` with a valid system target. The available
targets are,

- pi4
- pi5
- efi-arm64
- efi-amd64

If targeting a recent (> 2024) Raspberry Pi 4 or CM4, use the `pi5` target. For
more information about Rugix targets and boot flows, see
[here](https://oss.silitics.com/rugix/docs/ctrl/advanced/boot-flows/#available-boot-flows)

To speed up the build process and disable compression of update bundles, use
`just build <system> --without-compression`.

### Pushing the image to Aqago

To push the image to your Aqago backend, run `just push <reference>`. Reference
is a Docker-like reference, including the name, an optional tag, and variant.
Formally, `name[:tag[~variant]]`. More information is available in the Aqago
Backend documentation.

## Advanced and Experimental

# Running the Aqago Management CLI directly (Advanced)

Run `just cli`.

# Running a Test VM (Experimental)

`just run`

Connect via SSH (port 2222) to the VM and provision it with:

`ssh -p 2222 root@127.0.0.1 aqago-agent provision --api-key <api-key>`
