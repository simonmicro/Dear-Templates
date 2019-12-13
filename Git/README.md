# HowTo Git #

## Nett2Know ##
SSH-Key auth is heaven. You should use this. Really. If you commit and push a lot... You'll NEED it. Also it is more secure than having a GitHub access token copy-pasted for every push.

## Setup ##
`git init` Init of local repo

`git clone` Gets remote repo with all branches and history

Run this to configure your profile (omit `--global` for local repo only) - can also be modified inside .git/config:
* `git config --global user.name "[name]"`
* `git config --global user.email "[email]"` _Use the private repo mail (example: ID+DOMAIN+RND.USER@HOST), so nobody will get your private email!_


## Commands ##

### Commit ###
`git status` What branch is active? What are unstaged changes?

`git add` / `git rm` Add / Remove files or folder (-> `-r`) to the next commit...

`git commit` Commit! (without a `-m` nano will ask for more info)

`git fetch` Gets the newest commits without applying them. Good for updating the log...

`git pull` Gets the newest commits and apply them. Fails most the time due local newer commits.

`git push` Pushes HEADs branch to remote (ether specify with `origin [branch]` or on master directly it) - use `-f` **ONLY** if _someone_ has killed the repo / pushed to master directly

`git checkout -b [branch]` Creates a new branch...

`git merge [branch]` Checkout e.g. master and then run this to begin to merge of e.g. simon by using fast-forward-if-possible

`git branch -d [killme]` Deletes a branch...

### Working with the past... ###

`git log` Shows the last commits (with the local/remotes branch HEADS position(-s))...

`git checkout [existing branch / commit]` Update / Reset working directory to the histories point

### Who has pushed directly to the master? AGAIN? / What-Have-I-Done-Edition ###

`git diff [path]` Show the diff for a file

`git blame [path]` Show the responsible author for every line. **Who fucked that line up?!?**

### F**** ###

`git reset [commit]` Two known usages:
* Add `--hard` to reset working tree AND history! So make sure not to have a detached HEAD - otherwise... Bye, bye history!
* HEAD~n Move the HEAD n commit back (== revert commits without a "Reverting Commit"). Can't be used for any pushed commit!

`git fsck` Last chance before complete failure of the git folder structure (btw. thank you Nextcloud). If problem persists: Wipe everything. Doesn't work on most cases (like missing commit / history).

## .gitignore ##
Add a path per line to get it ignored! The path is NOT absolute!
-> `.directory` ignores Kubuntu-Files in every subfolder too. Neat.

## If the credentials file has been added... ##
Or a file bigger than 100MB. Or some private data has been commited - and already pushed:
[RESCUE IS HERE](https://help.github.com/en/github/managing-large-files/removing-files-from-a-repositorys-history)