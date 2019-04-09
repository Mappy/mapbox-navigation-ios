#!/usr/bin/env bash

set -e

SIMULATOR_VERSION=12.2

xcodebuild clean build -scheme "Example (Swift)" -destination "platform=iOS Simulator,name=iPhone 8,OS=${SIMULATOR_VERSION}" | xcpretty && exit ${PIPESTATUS[0]}

