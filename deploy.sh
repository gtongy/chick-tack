#!/bin/bash

# deploy github pages
echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
cd public
GIT_DIFF = `git diff --name-only`
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
if [ $GIT_DIFF ]; then
  git add .
  git commit -m "$msg"
fi
git push -f origin gh-pages
