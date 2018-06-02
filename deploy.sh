#!/bin/bash

# deploy github pages message
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi

# サイトを生成するディレクトリ
DIST_DIR=./public
echo "DIST_DIR : ${DIST_DIR}"
rm -rf ${DIST_DIR}/* || exit 0
./binaries/hugo -t "hugo-theme-cactus-plus"
cd ${DIST_DIR}
# 変更があったらcommit
git add -A .
echo ${msg}
git commit -m "${msg}"

# GitHubにpush
echo "Push to GitHub"
git push origin gh-pages > /dev/null 2>&1
echo "Successfully deployed."