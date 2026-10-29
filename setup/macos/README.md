## Re-capturing this machine

Run from the repo root on the machine you're capturing (`work-mac` or `personal-mac`):
~~~
brew bundle dump --file=setup/macos/Brewfile.<host> --force --describe
brew leaves | xargs brew desc --eval-all > setup/macos/brew-leaves.<host>.md
~~~
Review the diff before committing: a dump drops anything you added by hand.

## Homebrew Tips and Tricks

To upgrade homebrew
$ brew update

To upgrade all installed casks
$ brew upgrade

`brew leaves` shows you all top-level packages; packages that are not dependencies. This should be the most interesting if you are using the list to re-install packages.

To include formula descriptions, use
~~~
brew leaves | xargs brew desc --eval-all
~~~
To include cask descriptions, use
~~~
brew ls --casks | xargs brew desc --eval-all
~~~

It is possible to view the list of all the installed packages as a nicely formatted dependency tree. To view it, execute the following command:

brew deps --tree --installed

An example output is as shown below:
```html
<img src="brew-tree.jpg" alt="brew tree" width="250" height="250">
```


## Backing up and restoring brew installed files
creates Brewfile in the current directory from currently-installed packages
~~~
brew bundle dump
~~~

Install everything from the Brewfile
~~~
brew bundle
~~~