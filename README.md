delta.vim
=========

[Vim][] plugin for opening and managing diff windows between log changesets,
branch origins, merge parents and the working copy in a [Mercurial][]
repository.

Installation
------------

The following instructions should work on [POSIX.2][] compliant systems like
[GNU/Linux][] that offer a [Unix shell][] command-line interface.

### STEP 1 - Fetch the Vim plugin from [GitHub][delta.vim]

This step places the plugin files into a sub-directory of your home directory
called `delta.vim`.  You can use a different name and location.

 * EITHER clone it into a local directory using [Git][]:

        cd
        git clone https://github.com/quixotique/delta.vim.git

 * OR fetch the files as a [Zip][] archive, unpack them and rename the unpacked directory:

        cd /tmp
        wget https://github.com/quixotique/delta.vim/archive/master.zip
        unzip /tmp/master.zip
        cd
        mv /tmp/delta.vim-master delta.vim

 * OR fetch each file individually (the following commands may be incorrect or
   incomplete if files have been renamed or added since these instructions were
   written):

        cd
        mkdir delta.vim
        cd delta.vim
        mkdir plugin
        cd plugin
        wget https://raw.githubusercontent.com/quixotique/delta.vim/master/plugin/mercurial.vim
        cd ..
        mkdir syntax
        cd syntax
        wget https://raw.githubusercontent.com/quixotique/delta.vim/master/syntax/hglogcompact.vim

### STEP 2 - Add the plugin to Vim

The following instructions assume that STEP 1 placed the plugin files under the
`delta.vim` sub-directory of your home directory.  If you placed them in
another location, you must adapt the following instructions.

 * IF YOU USE [Pathogen][], move the cloned/unpacked/fetched plugin
   sub-directory created in STEP 1 to a place where it will be a Vim bundle:

        cd
        mkdir -p .vim/bundle
        mv delta.vim .vim/bundle

 * OR add the cloned/unpacked/fetched directory created in STEP 1 to your Vim
   [runtimepath][] by adding the following line to your [vimrc][] file:

        set runtimepath^=~/delta.vim

 * OR copy the cloned/unpacked/fetched files created in STEP 1 into your Vim
   settings:

        cd
        mkdir -p .vim/plugin
        cp delta.vim/plugin/*.vim .vim/plugin
        mkdir -p .vim/syntax
        cp delta.vim/syntax/*.vim .vim/syntax

How to use
----------

Once the plugin is installed, start [Vim][] and type the following command:

    \h

This should display a page of usage instructions for the Delta Vim plugin.

Copyright and license
---------------------

Copyright in the Vim plugin software, including any documentation embedded
within the plugin (such as comments and Vim help pages), is jointly held by
[Tuenti Technologies, S.L.][], [Andrew Bettison][], and any other contributors
listed in the source files.  The Vim plugin software is licensed to the public
under the under the [GNU General Public License 3.0][GPL3].

Copyright in any accompanying documentation not embedded in the plugin (such as
this file) is held by [Andrew Bettison][] and any other contributors listed in
the documentation files.  The accompanying documentation is licensed to the
public under the [Creative Commons Attribution 4.0 International licence][CC BY 4.0],
and every documentation file should bear a footer like the one in this
document.

History
-------

The Delta Vim plugin for [Mercurial][] was originally developed in 2011 by
[Andrew Bettison][] as an employee of [Tuenti Technologies, S.L.][] (in Madrid,
Spain).  Andrew later modified and improved the plugin in his own capacity, and
released it on [GitHub][delta.vim] in 2014 under public license with permission
from Tuenti.

-----
**Copyright 2014 Andrew Bettison**  
![CC-BY-4.0](./cc-by-4.0.png)
This document is available under the [Creative Commons Attribution 4.0 International licence][CC BY 4.0].

[delta.vim]: https://github.com/quixotique/delta.vim
[Vim]: http://www.vim.org/
[Mercurial]: http://mercurial.selenic.com/
[GPL3]: ./LICENSE-SOFTWARE.md
[CC BY 4.0]: ./LICENSE-DOCUMENTATION.md
[Tuenti Technologies, S.L.]: http://corporate.tuenti.com/en/corporate
[Andrew Bettison]: https://au.linkedin.com/in/andrewbettison
[POSIX.2]: http://en.wikipedia.org/wiki/POSIX
[Unix-like]: http://en.wikipedia.org/wiki/Unix-like
[GNU/Linux]: http://en.wikipedia.org/wiki/Linux
[Unix shell]: http://en.wikipedia.org/wiki/Unix_shell
[Git]: http://git-scm.com/
[Zip]: http://en.wikipedia.org/wiki/Zip_(file_format)
[Pathogen]: https://github.com/tpope/vim-pathogen
[runtimepath]: http://usevim.com/2012/12/28/vim-101-runtimepath/
[vimrc]: http://vim.wikia.com/wiki/Open_vimrc_file
[vim top 10]: http://www.oualline.com/vim/10/top_10.html
[Elvis]: http://elvis.the-little-red-haired-girl.org/whatiselvis/index.html
[nvi]: https://sites.google.com/a/bostic.com/keithbostic/vi
[vile]: http://invisible-island.net/vile/
[Busybox]: http://www.busybox.net/
