# bazzite-hyprland

Personal custom Bazzite image, created from the official
[Universal Blue image-template](https://github.com/ublue-os/image-template).

## Current stage: minimal baseline

- Base: `ghcr.io/ublue-os/bazzite:stable` (tracks the stable tag).
- Output: `ghcr.io/astroboii47/bazzite-hyprland:latest`.
- No extra packages or services. Hyprland is **not installed yet**.
- The existing Bazzite desktop remains included.
- No personal data, credentials, or laptop configuration belong in this repository.

The template's sample tmux installation and podman.socket enablement were removed.
Upstream template snapshot: `1dd3b656c4eb99dea9fbf9bd8210a754bd94adab`.

## Builds and signing

[Build status and logs](https://github.com/astroboii47/bazzite-hyprland/actions/workflows/build.yml)

The container workflow runs on pushes to main (except README-only changes), pull
requests to main, manual dispatch, and daily at 10:05 UTC. It builds on an x86_64
Linux runner, runs `bootc container lint`, and publishes dated
and commit-specific tags alongside `latest`. The image is pushed once; aliases
copy the published manifest and are checked against the same digest before it is
signed. This keeps every tag covered by the same signature.

The minimal baseline preserves Bazzite's existing layers. Optional rechunking
recipes remain available in the Justfile for later customization.

Only default-branch builds publish and sign. Pull requests build without publishing
or receiving the signing secret. The workflow checks signing configuration before
building and verifies the published image signature after signing.

`SIGNING_SECRET` is stored as an encrypted GitHub Actions repository secret.
Only the corresponding public key, `cosign.pub`, is committed. Keep any local
private-key backup secure; it is excluded by `.gitignore`.

## Next safe step

After a successful baseline build and signature verification, add a minimal
Hyprland session in a separate change, preserving the existing Bazzite desktop as
a fallback. Validate the image in a virtual machine before considering laptop
installation. This repository setup does not modify or rebase any laptop.

Optional disk/ISO tooling is inherited from the template and is not part of the
initial validation. `disk_config/iso.toml` uses the KDE installer configuration and
points at this repository's image. Do not launch the installer on the laptop yet.
