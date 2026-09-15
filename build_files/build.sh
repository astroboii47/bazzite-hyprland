#!/bin/bash
set -euo pipefail

# Stage 1: validate a signed Bazzite baseline before adding Hyprland.
# No additional packages, service changes, or personal configuration yet.
printf '%s\n' 'Building the minimal Bazzite baseline for bazzite-hyprland.'
