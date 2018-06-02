#!/bin/bash

# deploy github pages
echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
cd public
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git add .
git diff --cached --exit-code --quiet || git commit -m "$msg"
git push -f origin gh-pages