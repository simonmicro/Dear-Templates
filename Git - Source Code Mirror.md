---
summary: Full guide to Git, LFS and a common .gitignore
---

# HowTo Git #

## Nett2Know: Credentials ##
SSH-Key auth is heaven. You should use this. Really. If you commit and push a lot... You'll NEED it. Also it is more secure than having a GitHub access token copy-pasted for every push.
If you still need to use the HTTP-based remotes, you can configure the Git Credential Store. This will save the username/password as **plain text** to your disk - therefore only recommended when you must use Git LFS! To do that, just execute:
```bash
git config --global credential.helper store
```
...and every next HTTP-remote will only ask once for your credentials.

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

`git rebase [branch]` Should be used after a fetch, this rewinds your commits and applies them after each other to the branch to rebase on. Therefore your commits stay on top of the history, instead of getting merged into their time-based slots (this will also not create a merge commit).

`git pull` Gets the newest commits and apply them. This will also create a new "merge" commit, as it basically fetches and then merges the remote branch.

`git push` Pushes HEADs branch to remote (ether specify with `origin [branch]` or on master directly it) - use `-f` **ONLY** if _someone_ has killed the repo / pushed to master directly!

`git checkout -b [branch]` Creates a new branch...

`git checkout --orphan [branch]` Creates a new branch, but with no histroy (not really useful, except in special cases)...

`git merge [branch]` Checkout e.g. master and then run this to begin to merge of e.g. simon by using fast-forward-if-possible

`git branch -d [killme]` Deletes a branch...

### Working with the past... ###

`git log` Shows the last commits (with the local/remotes branch HEADS position(-s))...

`git checkout [existing branch / commit]` Update / Reset working directory to the histories point

### Who has pushed directly to the master? AGAIN? / What-Have-I-Done-Edition ###

`git diff [path]` Show the diff for a file

`git blame [path]` Show the responsible author for every line.

### F**** ###

`git reset [commit]` Two known usages:
* Add `--hard` to reset working tree AND history! So make sure not to have a detached HEAD - otherwise... Bye, bye history!
* HEAD~n Move the HEAD n commits back (== revert commits without a "Reverting Commit"). This could mess up your ability to push the branch, as any new commit overwrites the remote history!

`git fsck` Last chance before complete failure of the git folder structure. If problem persists: Wipe everything. Doesn't work on most cases (like missing commit / history).

`git gc` Cleans old, dangling commits from your disk (e.g. you ran `git reset` and therefore disgarded some commits).

## .gitignore ##
Add a path per line to get it ignored! The path is NOT absolute!

## Change Authorname and Authoremail in history ##
1. First time only (it's global): `git config --global alias.change-commits '!'"f() { VAR1=\$1; VAR='\$'\$1; OLD=\$2; NEW=\$3; echo \"Are you sure for replace \$VAR \$OLD => \$NEW ?(Y/N)\";read OK;if [ \"\$OK\" = 'Y' ] ; then shift 3; git filter-branch --env-filter \"if [ \\\"\${VAR}\\\" = '\$OLD' ]; then export \$VAR1='\$NEW';echo 'to \$NEW'; fi\" $@; fi;}; f "`
2. Now you can use...
    * `git change-commits GIT_AUTHOR_NAME "old name" "new name"`
    * `git change-commits GIT_AUTHOR_EMAIL "old@email.com" "new@email.com" HEAD~10..HEAD` (you can omit the `HEAD...` part)
[See here](https://stackoverflow.com/questions/2919878/git-rewrite-previous-commit-usernames-and-emails)

## If the credentials file has been added... ##
...or a file bigger than 100MB; or some private data has been commited - and already pushed:
[RESCUE IS HERE](https://help.github.com/en/github/managing-large-files/removing-files-from-a-repositorys-history)

# Git LFS #
...Imagine having a huge repository - lets say about 60 GB in files. But only some files are huge - lets also say they are all zip files. First activate LFS for your repo (don't forget to install the `git-lfs` package):
```bash
git lfs install
```
And specify which files you want to handle seperatly:
```bash
git lfs track "*.zip"
```
Thats it! Whenever you work from now on with e.g. GitLab this huge files will be compressed, downloaded only as needed and managed (much) faster!

_Note:_ As stated on the GitLab help page the Git LFS authentication does not require you to setup the credentieal store mentioned before:
> With 8.12 GitLab added LFS support to SSH. The Git LFS communication still goes over HTTP, but now the SSH client passes the correct credentials to the Git LFS client, so no action is required by the user.

# Signed Git #
As you may know, anyone could issue the `git config user.*` command and therefore commit _as-he-would-be-you_. This is clearly not the best thing, but sometimes neccessary (e.g. while using rebase).
To clearly mark those impersonating commits, just use gits PGP functionality! And this is how it is done:

1. Create a new key, either use the `seahorse` GUI or run `gpg2 --gen-key` (make sure to install `gnupg2` first).
2. Get the key id by either using `seahorse` again, or running `gpg2 --list-secret-keys --keyid-format LONG` (the id is behind the `sec rsa.../` part)
3. Export the public key by running `gpg2 --armor --export [KEY_ID]` - you should upload this now to an public PGP key server, e.g. [openpgp.org](https://keys.openpgp.org/) (this one verifies you are the emails owner and is also used inside Thunderbird). You could also use this key for signing (& encrypting) emails, messages, builds and much more! When you plan to use GitHub or GitLab, make sure to upload your key there aswell, as those systems do not use public key servers to download your public key automatically.
4. Enable git commit singing by executing `git config --global user.signingkey [KEY_ID]` and try to commit something using `git commit -S`.
5. When this works, you may enable singing for all your commits from now on by running `git config --global commit.gpgsign true`.

_Note_ You can always add more emails to your key or remove them. Also you can expire your sub-keys as needed, by just using `seahorse` and then re-uploading your key to the keyserver.

**Warning** When you upload your key it is out there for all eternity! The key infrastructure is designed to ensure this! When you ever want to revoke a key you must have your revocation certificate!
To get it run `gpg2 --output revokce.asc --gen-revoke [KEY_ID]` (`seahorse` can't do this for you) and then upload it as needed.

# Basic .gitignore #
...for the most files from me - a more complete list is [here](https://github.com/github/gitignore)...
```
# Netbeans
**/nbproject/
**/dist/
**/build/
.dep.inc

# (C)Make
**/CMakeFiles/
CMakeCache.txt
cmake_install.cmake
Makefile

# Kubuntu
.directory

# MacOSX
.DS_Store

# block directory for binaries
bin/

# Doxygen stuff
doc/

# CLion
.idea/
cmake-build-debug/

# Visual Studio Code
.vscode
```
