#!/bin/bash
set -e

# Constants
CHART_DIR="charts/galaxy"
OUTPUT_DIR="charts"
PUBLISH_BRANCH="gh-pages"
WORKING_BRANCH="galaxy-5.19.0-custom"
CHART_REPO_URL="https://estrain.github.io/galaxy-helm-custom"

echo "Checking out working branch: $WORKING_BRANCH"
git checkout $WORKING_BRANCH

# Get version from Chart.yaml
CHART_VERSION=$(grep '^version:' $CHART_DIR/Chart.yaml | awk '{print $2}')
PACKAGE_NAME="galaxy-$CHART_VERSION.tgz"

echo "Packaging chart version $CHART_VERSION"
rm -f $OUTPUT_DIR/*.tgz
helm package $CHART_DIR -d $OUTPUT_DIR

echo "Rebuilding index.yaml"
helm repo index $OUTPUT_DIR --url $CHART_REPO_URL

# Save packaged files before switching branches
TMP_DIR=$(mktemp -d)
cp $OUTPUT_DIR/$PACKAGE_NAME $TMP_DIR/
cp $OUTPUT_DIR/index.yaml $TMP_DIR/

# Reset local changes so we can switch branches
echo "Cleaning up local changes before switching branches"
git restore --staged .
git checkout -- .
git clean -fd

echo "Switching to publish branch: $PUBLISH_BRANCH"
git checkout $PUBLISH_BRANCH

echo "Removing old files from $PUBLISH_BRANCH"
rm -f *.tgz index.yaml

echo "Copying new files"
cp $TMP_DIR/$PACKAGE_NAME .
cp $TMP_DIR/index.yaml .

echo "Committing and pushing to $PUBLISH_BRANCH"
git add .
git commit -m "Publish chart version $CHART_VERSION"
git push origin $PUBLISH_BRANCH

echo "Done. Chart version $CHART_VERSION published to GitHub Pages."

# Clean up
rm -rf $TMP_DIR

