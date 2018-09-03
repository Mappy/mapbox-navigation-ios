#!/usr/bin/env bash

set -e

SIMULATOR_VERSION=11.4

#xcodebuild clean build -scheme MapboxNavigation -destination "platform=iOS Simulator,name=iPhone 8,OS=${SIMULATOR_VERSION}" | xcpretty && exit ${PIPESTATUS[0]}

xcodebuild clean build -scheme Example-Swift -destination "platform=iOS Simulator,name=iPhone 8,OS=${SIMULATOR_VERSION}" | xcpretty && exit ${PIPESTATUS[0]}

