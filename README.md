# duplicacy-dev

This directory contains a Makefile for cloning, maintaining and
building forks of [Gilbert Chen's Duplicacy backup
software](https://github.com/gilbertchen/duplicacy).  It can also
be used to clone and build the original sources.

## Setup and Initial Build

Edit the `Makefile` and set the value of `REPO` to point at a Git repo
containing a forked copy of Duplicacy.

Run `make` to clone and build everything.  Note that this process does
not re-use anything in your `$GOPATH`, opting instead for a
completely-standalone copy.


## Development and Build

A symbolic link called `work` will take you directly into the part of
the Go directory where the Duplicacy sources live.

Make changes, do commits and anything else you'd normally do while working.

Build the Duplicacy binary by running `make`.

If the build is successful, a symbolic link called `duplicacy` will
appear in the top-level directory.  (Conversely, if the build fails,
that symbolic link will disappear.)


## Housekeeping

Before commiting changes, `make unpatch` will remove a change to one
file that makes Duplicacy compile outside of Gilbert Chen's environment.

A `make clean` will remove everything not distributed with this
repository.  If changes to the sources other than the aforementioned
patch are detected, nothing will be done.  This check can be bypassed
by doing a `make clean-force`.
