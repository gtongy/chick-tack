#!/bin/bash

git clone git@github.com:gtongy/chick-tack.git
cd chick-tack
git clone https://github.com/nodejh/hugo-theme-cactus-plus.git ./themes/hugo-theme-cactus-plus
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
git init
git add -A .
echo ${msg}
git commit -m "${msg}"

# GitHubにpush
echo "Push to GitHub"
git push origin gh-pages > /dev/null 2>&1
echo "Successfully deployed."