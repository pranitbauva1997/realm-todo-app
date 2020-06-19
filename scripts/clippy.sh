#!/usr/bin/env bash

set -e
cargo-clippy --all --tests -- -Dwarnings
# cargo test --all
