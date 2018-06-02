#!/bin/bash

# deploy github pages message
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi

# サイトを生成するディレクトリ
DIST_DIR=./public
echo "DIST_DIR : ${DIST_DIR}"

# 変更があったらcommit
cd ${DIST_DIR}
git add .
d=`date +"%Y/%m/%d %k:%M:%S"`
git diff --cached --exit-code --quiet || git commit -m "${msg}"

# GitHubにpush
echo "Push to GitHub"
git push origin gh-pages > /dev/null 2>&1
echo "Successfully deployed."