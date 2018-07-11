#!/bin/sh

UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${CONFIGURATION}-universal

# make sure the output directory exists
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}/iOS"

TARGET_NAME='MapboxDirections'
SCHEME_NAME='MapboxDirections iOS'

# Step 1. Build Device and Simulator versions on iOS
xcodebuild -scheme "${SCHEME_NAME}" -configuration ${CONFIGURATION} -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6' clean build
xcodebuild -scheme "${SCHEME_NAME}" -configuration ${CONFIGURATION} -sdk iphoneos clean build

# Step 2. Copy the framework structure (from iphoneos build) to the universal folder
cp -R "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${TARGET_NAME}.framework" "${UNIVERSAL_OUTPUTFOLDER}/iOS"

cp -R "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${TARGET_NAME}.framework/Modules/MapboxDirections.swiftmodule/" "${UNIVERSAL_OUTPUTFOLDER}/iOS/${TARGET_NAME}.framework/Modules/MapboxDirections.swiftmodule/"

# Step 3. Create universal binary file using lipo and place the combined executable in the copied framework directory
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/iOS/${TARGET_NAME}.framework/${TARGET_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${TARGET_NAME}.framework/${TARGET_NAME}" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/${TARGET_NAME}.framework/${TARGET_NAME}"

DESTINATION_DIR="pkg/Frameworks-${CONFIGURATION}"
echo "Creating ${DESTINATION_DIR}"

mkdir -p ${DESTINATION_DIR}

echo "Copying ${TARGET_NAME}.framework to ${DESTINATION_DIR}"

cp -R "${UNIVERSAL_OUTPUTFOLDER}/iOS/${TARGET_NAME}.framework" "${DESTINATION_DIR}"
