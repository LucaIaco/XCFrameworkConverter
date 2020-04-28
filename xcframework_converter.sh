#!/bin/sh

# Converts an existing compiled .framework to his equivalent .xcframework
# 
# It will:
# 1) Detect all the architectures in the source framework
# 2) A separate .framework folder copy of the source one will be created per each architecture and the executable will be replaced with the extracted specific architecture
# 3) Clean the unrelated architecture files across the generated .framework folders ( eg. swift modules in the arm64 should contain therefore only arm64 swift module files)
# 4) Execute the command to convert the generated frameworks into an XCFramework form
#
# Created by Luca Iaconis
# Copyright © 2020 Luca Iaconis. All rights reserved.
#

# The absolute input path to the <FRAMEWORKNAME>.framework
INPUT_FRAMEWORK_PATH=$1
# The absolute output folder where to save the XCFrameowork
OUTPUT_XCFRAMEWORK_PATH="${PWD}/OutputFramework"
# Get the framework executable name from the info plist file
FRAMEWORK_EXECUTABLE_NAME=$(/usr/libexec/PlistBuddy -c 'print ":CFBundleExecutable"' $INPUT_FRAMEWORK_PATH/Info.plist)
# Path to the framework executable
FRAMEWORK_EXECUTABLE_PATH="$INPUT_FRAMEWORK_PATH/$FRAMEWORK_EXECUTABLE_NAME"
# The framework folder name
FRAMEWORK_FOLDER_NAME="$FRAMEWORK_EXECUTABLE_NAME.framework"
# Get all the included architectures in the provided framework
eval "ARCHS=($(lipo -archs $FRAMEWORK_EXECUTABLE_PATH))"
# Array of double quoted extracted frameworks
FRAMEWORKS=()
# Remove any existing output folder
rm -rvf "$OUTPUT_XCFRAMEWORK_PATH" > /dev/null 2>&1
# For each detected architecture in the source framework
for ARCH in "${ARCHS[@]}"; do 
    # create architecture specific framework path
    mkdir -p "$OUTPUT_XCFRAMEWORK_PATH/$FRAMEWORK_EXECUTABLE_NAME-$ARCH" > /dev/null 2>&1
    cp -r "$INPUT_FRAMEWORK_PATH" "$OUTPUT_XCFRAMEWORK_PATH/$FRAMEWORK_EXECUTABLE_NAME-$ARCH/$FRAMEWORK_FOLDER_NAME" > /dev/null 2>&1
    rm "$OUTPUT_XCFRAMEWORK_PATH/$FRAMEWORK_EXECUTABLE_NAME-$ARCH/$FRAMEWORK_FOLDER_NAME/$FRAMEWORK_EXECUTABLE_NAME" > /dev/null 2>&1
    # remove any other architecture data (eg. swift modules) which is not the current one
    for SEEK_ARCH in "${ARCHS[@]}"; do 
        if [[ "$SEEK_ARCH" != "$ARCH" ]]; then 
            find "$OUTPUT_XCFRAMEWORK_PATH/$FRAMEWORK_EXECUTABLE_NAME-$ARCH/$FRAMEWORK_FOLDER_NAME" -name "$SEEK_ARCH*" -exec rm {} \; 
        fi;
    done
    lipo -extract "$ARCH" "$FRAMEWORK_EXECUTABLE_PATH" -o "$OUTPUT_XCFRAMEWORK_PATH/$FRAMEWORK_EXECUTABLE_NAME-$ARCH/$FRAMEWORK_FOLDER_NAME/$FRAMEWORK_EXECUTABLE_NAME" > /dev/null 2>&1
    FRAMEWORKS+=("\"$OUTPUT_XCFRAMEWORK_PATH/$FRAMEWORK_EXECUTABLE_NAME-$ARCH/$FRAMEWORK_FOLDER_NAME\"")
done

# function which convert an array to a string with provided delimiter as first parameter, and the array as second one
combine() {
  (($#)) || return 1 # At least delimiter required
  local -- delim="$1" str IFS=
  shift
  str="${*/#/$delim}" # Expand arguments with prefixed delimiter (Empty IFS)
  #echo "${str:${#delim}}" # Echo without first delimiter
  echo "${str}" # Echo with first delimiter
}
# String representation of the list of architectures-frameworks to be moved into the final XCFramework
XCFRAMEWORKS_INPUT=$(combine ' -framework ' "${FRAMEWORKS[@]}")
# Execute the command
CREATE_XCFRAMEWORK_CMD="xcodebuild -create-xcframework$XCFRAMEWORKS_INPUT -output \"$OUTPUT_XCFRAMEWORK_PATH/$FRAMEWORK_EXECUTABLE_NAME.xcframework\""
eval $CREATE_XCFRAMEWORK_CMD
# Cleanup temporary frameworks
for ARCH in "${ARCHS[@]}"; do 
    rm -rvf "$OUTPUT_XCFRAMEWORK_PATH/$FRAMEWORK_EXECUTABLE_NAME-$ARCH" > /dev/null 2>&1
done