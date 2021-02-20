echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

cd public

git init
git add .
git commit -m "Rebuild site"

git remote add origin "https://${GITHUB_AUTH_SECRET}@github.com/DreamAndDead/DreamAndDead.github.io.git" 
git push --force origin HEAD:master

