#!/bin/bash

git clone --quiet https://$GH_TOKEN@github.com/gtongy/chick-tack.git
cd chick-tack
git clone https://github.com/nodejh/hugo-theme-cactus-plus.git ./themes/hugo-theme-cactus-plus
git fetch origin gh-pages:remotes/origin/gh-pages
git worktree add -B gh-pages public origin/gh-pages
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
git add --all
echo ${msg}
git commit -m "${msg}"

# GitHubにpush
echo "Push to GitHub"
git push --quiet origin gh-pages > /dev/null 2>&1
echo "Successfully deployed."