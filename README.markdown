# Vnews

Vnews is a fast, lightweight newsfeed reader built on top of Vim and
MySQL.

[screenshots]

There are lots of newsfeed readers out there, both desktop and
web-based. Here are some of Vnews's advantages: 

* minimizes distractions; everything is rendered as plain text and pure content; images and ads are not displayed
* makes it easy to navigate your entire feed collection using efficient keystrokes 
* makes it easy to copy, append, or pipe text from your feeds to whatever file or program you want

Vnews uses MySQL to store your feed data locally. It uses MySQL's MyISAM
tables to provide natural-language full-text search capability.


## Prerequisites

* a recent version of Vim (Vnews is developed against Vim 7.2)
* a recent version of Ruby: Ruby 1.9.2 is recommended
* MySQL
* the Unix program `tidy` 
* the Unix program `fmt` 

Vnews assumes a Unix environment. 

To install Ruby 1.9.2, I recommend using the [RVM Version Manager][rvm],
which makes it easy to install and manage different versions of Ruby.

[rvm]:http://rvm.beginrescueend.com

## Installation

    gem install vnews

Test your installation by typing `vnews -h`. You should see Vnews's help.

If you run into any PATH errors, try the following: Install the RVM
Version Manager, then install Ruby 1.9.2 through RVM, and then run `gem
install vnews`.  This should solve any installation issues.

If you ever want to uninstall Vnews from your system, execute this command:

    gem uninstall vnews

... and all traces of Vnews will removed.

New and improved versions of Vnews will be released over time. To install the
latest version, just type `gem install vnews` again.


## Setup

    vnews

When you run Vnews for the first time, a `.vnewsrc` configuration file will be
generated in your home directory. The top of this file will look like
this:

    host: localhost 
    database: vnews 
    username: root 
    password: 
 
You must edit this file to match your MySQL settings, and then run 

    vnews --create-db

to generate the MySQL database that will store your feed data. Leave
`password:` blank if you don't use a MySQL password.

To use MacVim as your Vnews Vim engine, you can run vnews like this

    VNEWS_VIM=mvim vnews

or you can `export VNEWS_VIM=mvim` in your `~/.bash_profile` and then
just run `vnews`.

## Configuring your feeds

To configure your feeds, edit the bottom part of the `.vnewsrc` file.
The bottom part of the file looks like this:

    General News 
    http://feedproxy.google.com/economist/full_print_edition
    http://feeds.feedburner.com/TheAtlanticWire
    
    Humor
    http://feed.dilbert.com/dilbert/blog
    
    Tech 
    http://rss.slashdot.org/Slashdot/slashdot
    http://feeds2.feedburner.com/readwriteweb
    http://feedproxy.google.com/programmableweb
    http://news.ycombinator.com/rss
    http://daringfireball.net/index.xml
    http://dailyvim.blogspot.com/feeds/posts/default
    
The configuration syntax is very simple. Feeds are organized into
folders, e.g. "General News". Under each folder name, list the feeds you
want to go inside that folder. You may put a feed under more than one
folder. Feeds are listed by their URLs.  These should point to live Atom
or RSS content.  

Whenever you change the feed/folder configuration, run this command: 

    vnews -u

This will update the Vnews datastore to reflect the changes (including
removing feeds). Then Vnews will update all your feeds and start a Vnews
session.  If you don't want to start a Vnews session (e.g. if you want
to run this as a cron job), use `vnews -U` instead.


## Basic navigation

To start Vnews, use `vnews -u` to update all your feeds before starting
your Vnews session. To simply start the session without going through
the update process, use the simple `vnews` command.

At this point, you should see the feed items for all your feeds
in one consolidated list.

* `j` moves up the item list
* `k` moves down the item list
* `ENTER` from the list window displays the item under the cursor and focuses the item window
* `ENTER` from item window returns focus to the list window
* `C-l` displays the item under the cursor without focusing the item window
* `SPACE` toggles full-screen mode for the current window.
* `C-j` shows the next item without changing window focus
* `C-k` shows the previous item without changing window focus

You can also use the standard Vim window switching, rotating, and
positioning commands.


## Navigating feeds and folders

* `,n` calls up the folder selection window
* `,m` calls up the feed selection window, sorted alphabetically
* `,M` calls up the feed selection window, sorted by the number of times you read an item from each feed

For all of the commands, you'll see an autocomplete window appear at the
top.  The standard Vim autocomplete keystrokes apply:

* `C-p` and `C-n` move you up and down the match list
* `C-e` closes the match list and lets you continue typing
* `C-u`: when the match list is active, cycles forward through the match list and what you've typed so far; when the match list is inactive, erases what you've typed.
* `C-x C-u` finds matches for what you've typed so far (when the match list window is closed)
* `C-y` selects the highlighted match without triggering ENTER
* ENTER selects the highlighted match from the match list 

TIP: start typing the first 1-3 characters of the mailbox name, then
press `C-n`, `C-u` or `C-p` until you highlight the right match, and
finally press ENTER to select.


## Unread items

Unread items are marked with a `+` symbol.


## Starring items

You can star interesting feed items by using `,*` or `,8` (both use the
same keys, the only difference being the SHIFT key). Starred items are
colored green and made available in a specially `Starred` folder.

Starred items don't get deleted when you remove the feed they came
from from your `.vnewsrc` configuration file. 

To unstar an item, press `,*` or `,8`  on a starred item.


## Deleting items

To delete items, use `,#` or `,3`. 

You can also delete a range of items, e.g. if you wanted to clear out a
backlog of items in a feed or folder.  To delete a range of items, you
can either of these methods:

* make a selection of rows in visual mode and type `:VNDelete`
* specify a line number range with the command: `:{range}VNDelete`

See `:help 10.3` to learn how to specify command line ranges.

You can use `:VND` as an abbreviation for `:VNDelete`.


## Opening webpages and hyperlinks

* `,o` opens the next web hyperlink on or after the cursor in your default external web browser
* `,h` opens the web page that the feed item is linked to

Web hyperlinks  are the URLs that begin with http:// or https://. 

Under the covers, Vnews uses the command `gnome-open` or `open` to
launch your external web browser. This should cover Linux Gnome desktop
and OS X users. You can change the command Vnews uses to open a
hyperlink by adding this to your `~/.vimrc`:

    let g:Vnews#browser_command = "your browser command here"

If your Vim has `netrw` installed, you can open a hyperlink directly in
Vim by putting the cursor on a web hyperlink and typing `gf`, `CTRL-W f`
or `,O` (capital O). All these commands open the webpage inside your Vim
session using `elinks` or whatever browser you set as your
`g:netrw_http_cmd`.  See `:help netrw` for more information.


## Concatenating feed items

* `:VNConcat` with a visual selection
* `:{range}VNConcat`

These commands let you concatenate feed items into a single, continuous
text document for printing or more leisurely reading.

See `:help 10.3` to learn how to specify command line ranges.


## Updating your feeds


Starting vnews with 

    vnews -u

will update all your feeds before opening the Vnews session.

    vnews -U

will update all your feeds without starting a session. You might want to
use this option if you want to update your feeds periodically in the
background using `cron`.

If you're already in a Vnews session, you can update the current feed of
folder by pressing `u`. 

## OPML import

If you want to import an OPML list of your feed subscriptions into
Vnews, use this command:

    vnews --opml [file]

`[file]` is your OPML file. 

You can easily import your Google Reader subscriptions this way. 
Here's [a video][export-tutorial] that shows you how to export your Google Reader
subscriptions to an OPML file.

[export-tutorial]:http://www.clipotech.com/2007/06/opml-export-in-google-reader.html


## Getting help

Typing `,?` will open the help webpage in a browser.


## Bug reports and feature requests

Vnews is very new, so there are kinks and bugs to iron out and lot of
desirable features to add.  If you have a bug to report or a good feature to
suggest, please file it on the [issue tracker][1].  That will help a lot.

[1]:https://github.com/danchoi/vnews/issues

You can also join the [Google Group][group] and comment there.

[group]:http://groups.google.com/group/vnews-users?msg=new&lnk=gcis

## How to contact the developer

My name is Daniel Choi. I am based in Cambridge, Massachusetts, USA, and you
can email me at dhchoi {at} gmail.com.  









