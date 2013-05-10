#/usr/bin/bash

rake generate
rake deploy
git add .
git commit -m 'no msg'
git push origin source
