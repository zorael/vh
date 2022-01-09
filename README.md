# vh

Terminal tool to print the head of files. Like `head`, but with colours.

```
usage: vh [--lines NUMBER] [--colours [BOOL]] [-h]

Optional arguments:
  --lines NUMBER, -n NUMBER
                          Number of lines to display.
  --colours [BOOL], --colors [BOOL], -c [BOOL]
                          Whether or not to use coloured output.
  -h, --help              Show this help message and exit
```

## Compiling

You need a D compiler and the `dub` package manager.

```sh
$ dub build
```