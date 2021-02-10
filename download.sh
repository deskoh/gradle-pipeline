#!/bin/bash

set -e

TIMESTAMP=`date +%Y%m%d-%H%M`

TARGET_DIR=target
MACHINERY_DIR=machinery
STUBS_DIR=$MACHINERY_DIR/stubs
BUILD_SCRIPT=$MACHINERY_DIR/build.gradle
SETTINGS_SCRIPT=$MACHINERY_DIR/settings.gradle
GRADLE_WRAPPER_PROPERTIES=$MACHINERY_DIR/gradle/wrapper/gradle-wrapper.properties
REPO_LIST_DIR=repolists
PACKAGE_LIST_DIR=pkglists
PLUGIN_LIST_DIR=pluginlists
GRADLE_CACHE_DIR=~/.gradle/caches/modules-2/files-2.1
OFFLINE_REPOSITORY_NAME=offline-repository

mkdir -p $TARGET_DIR
mkdir -p $PLUGIN_LIST_DIR
mkdir -p $PACKAGE_LIST_DIR
mkdir -p $REPO_LIST_DIR
mkdir -p $MACHINERY_DIR/$OFFLINE_REPOSITORY_NAME

# Configure Gradle Wrapper
echo "Configuring Gradle Wrapper..."

cat $STUBS_DIR/gradle-wrapper.properties.stub > $GRADLE_WRAPPER_PROPERTIES
cat gradle-wrapper-path.txt | sed 's/:/\\:/g' | sed 's/\(.*\)/distributionUrl=\1/g' >> $GRADLE_WRAPPER_PROPERTIES

# Generate Gradle Build Script
echo "Generating build script..."

cat $STUBS_DIR/build.gradle.stub1 > $BUILD_SCRIPT

if [ "$(ls $PLUGIN_LIST_DIR/*.txt 2> /dev/null)" ]
then
  cat $PLUGIN_LIST_DIR/*.txt | sed 's/\r//g' | sort | uniq | sed 's/^/  /g' >> $BUILD_SCRIPT
else
  echo "No plugin lists found."
fi

cat $STUBS_DIR/build.gradle.stub2 >> $BUILD_SCRIPT
cat $STUBS_DIR/settings.gradle.stub1 > $SETTINGS_SCRIPT

if [ "$(ls $REPO_LIST_DIR/*.txt 2> /dev/null)" ]
then
  cat $REPO_LIST_DIR/*.txt | sed 's/\r//g' | sort | uniq | sed 's/^\(.\+\)$/  maven \{\n    url "\1"\n  \}/g' >> $BUILD_SCRIPT
  cat $REPO_LIST_DIR/*.txt | sed 's/\r//g' | sort | uniq | sed 's/^\(.\+\)$/    maven \{\n      url "\1"\n    \}/g' >> $SETTINGS_SCRIPT
else
  echo "ERROR: You have not defined any repositories! The tool will not know where to download packages from unless you do."
  exit 1
fi

cat $STUBS_DIR/settings.gradle.stub2 >> $SETTINGS_SCRIPT

cat $STUBS_DIR/build.gradle.stub3 >> $BUILD_SCRIPT

if [ "$(ls $REPO_LIST_DIR/*.txt 2> /dev/null)" ]
then
  cat $REPO_LIST_DIR/*.txt | sort | uniq | sed 's/^\(.\+\)$/    maven \{\n      url "\1"\n    \}/g' >> $BUILD_SCRIPT
fi

cat $STUBS_DIR/build.gradle.stub4 >> $BUILD_SCRIPT

if [ "$(ls $PACKAGE_LIST_DIR/*.txt 2> /dev/null)" ]
then
  cat $PACKAGE_LIST_DIR/*.txt | sed 's/\r//g' | sort | uniq | sed 's/^\(.\+\)$/  api "\1"/g' >> $BUILD_SCRIPT
else
  echo "No package lists found."
fi

echo "}" >> $BUILD_SCRIPT

# Clear cache
echo "Clearing Gradle cache..."
rm -rf ~/.gradle/caches/*

cd $MACHINERY_DIR

# echo "Clearing download folder..."
# rm -rf $OFFLINE_REPOSITORY_NAME
# mkdir $OFFLINE_REPOSITORY_NAME

echo "Downloading..."
./gradlew updateOfflineRepository

# Create directories for omitted packages
for group_path in $GRADLE_CACHE_DIR/*
do
  group=$(basename $group_path)
  group_dir=$(echo $group | awk 'BEGIN{FS=OFS="/"} {gsub(/\./, "/", $1)} 1')
  for artifact_path in $group_path/*
  do
    artifact=$(basename $artifact_path)
    for version_path in $artifact_path/*
    do
      version=$(basename $version_path)
      path_to_create="$OFFLINE_REPOSITORY_NAME/$group_dir/$artifact/$version"
      mkdir -p $path_to_create
      find $version_path -type f -exec cp -n {} $path_to_create/ \;
    done
  done
done

echo "Packaging..."
cd $OFFLINE_REPOSITORY_NAME
zip -r ../../$TARGET_DIR/jars-$TIMESTAMP.zip *
cd ..

echo "Clearing download folder..."
rm -rf $OFFLINE_REPOSITORY_NAME

echo "Done."

./gradlew --stop