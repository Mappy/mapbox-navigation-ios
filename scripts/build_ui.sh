#!/usr/bin/env bash

set -e

#xcodebuild clean build -scheme MapboxNavigation -destination "platform=iOS Simulator,name=iPhone 8" | xcpretty && exit ${PIPESTATUS[0]}

xcodebuild clean build -scheme Example -destination "platform=iOS Simulator,name=iPhone 8" | xcpretty && exit ${PIPESTATUS[0]}

