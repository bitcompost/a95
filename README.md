a95 is a window manager built on top of arcan, written in Fennel.
Still experimental, use at your own risk :)

How to launch?
====

    arcan -g /path/to/a95

Note: The -g flag is necessary. Why? To make the loadstring Lua function avalible.
Why? So the Fennel compiler can compile functions. Why do we run a whole 
Fennel compiler on top of arcan? For interactive development and Fennel aware
backtraces.

