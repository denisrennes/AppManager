#!/bin/sh
# Build AppManager's zsync client (tools/zsync-rs) for bundling
# Usage: build-zsync-rs.sh <cargo> <source_dir> <output_dir>
#
# The client is the zsync-rs library (pure Rust, rustls TLS) plus progress
# output for the update indicator. It replaces the AppImageCommunity zsync2
# binary, which links the end-of-life OpenSSL 1.1.
# Installed as zsync-rs so it never shadows a distro zsync.

set -e

CARGO="${1:-cargo}"
SOURCE_DIR="$2"
OUTPUT_DIR="${3:-.}"

mkdir -p "$OUTPUT_DIR"

# --locked builds exactly the versions in tools/zsync-rs/Cargo.lock.
"$CARGO" build --release --locked \
    --manifest-path "$SOURCE_DIR/Cargo.toml" \
    --target-dir "$OUTPUT_DIR/zsync-rs-target"
cp "$OUTPUT_DIR/zsync-rs-target/release/zsync-rs" "$OUTPUT_DIR/zsync-rs"
chmod +x "$OUTPUT_DIR/zsync-rs"

echo "zsync-rs installed to $OUTPUT_DIR"
