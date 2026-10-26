#!/bin/sh
# Build the zsync-rs client from crates.io for bundling
# Usage: build-zsync-rs.sh <cargo> <version> <output_dir>
#
# zsync-rs is pure Rust with rustls TLS, and its --json flag reports download
# progress for the update indicator. It replaces the AppImageCommunity zsync2
# binary, which links the end-of-life OpenSSL 1.1.
# Installed as zsync-rs so it never shadows a distro zsync.

set -e

CARGO="${1:-cargo}"
VERSION="$2"
OUTPUT_DIR="${3:-.}"

mkdir -p "$OUTPUT_DIR"

# --locked builds exactly the versions in the crate's own Cargo.lock.
"$CARGO" install zsync-rs --version "=$VERSION" --locked --bin zsync \
    --root "$OUTPUT_DIR/zsync-rs-root" \
    --target-dir "$OUTPUT_DIR/zsync-rs-target"
cp "$OUTPUT_DIR/zsync-rs-root/bin/zsync" "$OUTPUT_DIR/zsync-rs"
chmod +x "$OUTPUT_DIR/zsync-rs"

echo "zsync-rs $VERSION installed to $OUTPUT_DIR"
