#!/usr/bin/env bash

set -e

SIMULATOR_VERSION=12.2

#xcodebuild clean build -scheme MapboxNavigation -destination "platform=iOS Simulator,name=iPhone 8,OS=${SIMULATOR_VERSION}" | xcpretty && exit ${PIPESTATUS[0]}

xcodebuild clean build -scheme Example -destination "platform=iOS Simulator,name=iPhone 8,OS=${SIMULATOR_VERSION}" | xcpretty && exit ${PIPESTATUS[0]}

