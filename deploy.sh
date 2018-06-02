#!/bin/bash

DIST_DIR=./public
echo "DIST_DIR : ${DIST_DIR}"
cd ${DIST_DIR}
git add .
d=`date +"%Y/%m/%d %k:%M:%S"`
git diff --cached --exit-code --quiet || git commit -m "$msg"
echo "Push to GitHub"
git push origin gh-pages > /dev/null 2>&1
echo "Successfully deployed."