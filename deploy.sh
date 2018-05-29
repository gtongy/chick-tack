#!/bin/bash

# Install Hugo
wget https://github.com/gohugoio/hugo/releases/download/v0.37/hugo_0.37_Linux-64bit.tar.gz
tar -xzf hugo_0.37_Linux-64bit.tar.gz
sudo mv hugo /usr/local/bin/

# deploy github pages
echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"
hugo -t "hugo-theme-cactus-plus"
cd public
git add .
msg="rebuilding site `date`"
if [ $# -eq 1 ]
  then msg="$1"
fi
git commit -m "$msg"
git push -f origin gh-pages
cd ..
