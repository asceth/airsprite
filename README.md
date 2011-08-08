Overview
--------
airsprite makes single png spritesheets from a directory struture and outputs parseable itx files for the http://www.madewithmarmalade.com (Marmalade SDK).


Give a directory as an argument.  Each folder underneath that directory is considered its own spritesheet.

Each png file underneath the spritesheet folder is a sprite in of itself (single frame) and constructs a default animation, default frame of that sprite.  If a folder is encounted a sprite is created named after the folder.

Inside the sprite folder, png files are considered animations with single frames with the name of the png file.  A folder is considered an animation called the name of the folder and each png file underneath the animation is a series of frames, sorted alphabetically.

Examples:

path/sprite.png
    /foo/bar.png

* creates a sprite called "sprite" with the "default" animation and a single frame called "idle".
* creates a sprite called "foo" with the "bar" animation and a single frame called "bar".



path/cranky/idle/0.png
            idle/1.png

path/cranky/run/0.png
            run/1.png

* creates a sprite named "cranky" with the "idle" and "run" animations each with two frames called "0" and "1".


Usage
--------

    airsprite path/to/dir

Install
-------

    gem install airsprite


Deps
-------

gem install rmagick

* used to create the spritesheet png


Author
------

Original author: John "asceth" Long


