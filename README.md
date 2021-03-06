# vh  [![Build Status](https://travis-ci.org/zorael/vh.svg?branch=master)](https://travis-ci.org/zorael/vh)

![vh of /proc/sys/vm](https://i.imgur.com/6WMZkGo.png)

This tool acts like the terminal tool `head`, verbosely performed on all files in the current directory or on paths specified on the command-line.

By default only the first three lines are shown, as `head -n3 *` would have displayed, but the line count is configurable via command-line switches. There is support for coloured output and on Posix systems this will default to enabled, whereas on Windows it defaults to off. The behaviour can be overridden with the `--colour` switch. See the `--help` menu for a listing of all switches.

## Getting started

You need a D compiler, and the official `dub` package manager is recommended. It is however very possible to build the project without it.

There are three compilers available; see [here](https://wiki.dlang.org/Compilers) for an overview. As of October 2017, `vh` can be built using any of them.

### Downloading

GitHub offers downloads in ZIP format, but it's easier to use `git` and clone the repository that way.

´´´bash
$ git clone https://github.com/zorael/vh.git
$ cd vh
´´´

### Compiling

´´´bash
$ dub build
´´´

This will compile it in the default `debug` mode, which adds some extra code and debugging symbols. You can build it in `release` mode by passing `-b release` as an argument to `dub`. Refer to the output of `dub build --help` for more build types.

Unit tests are built into the language, but you need to compile in `unittest` mode for them t
to run. The shorthand form for this is `dub test`;

´´´bash
$ dub test
´´´

The tests are run at the *start* of the program, not during compilation.

## How to use

Merely place the `vh` executable somewhere in your `PATH`, and execute it as you would anything else. Alternatively for fast tests after changes to the source, you can use `dub run`.

## TODO
* add unit tests
* code cleanup

## License
This project is licensed under the **MIT License**; see the [LICENSE](LICENSE) file for details.
