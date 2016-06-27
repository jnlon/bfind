# bfind

`bfind` is similar to the Unix `find(1)` command, but unlike GNU find, it searches for files
breadth first instead of depth first.

A breadth first search is useful if you are looking for a nearby file with
something like:

`find ~ | grep myfile`

If your `~` has heavily nested directories, then it may take a while for `find`
to print what your grepping for. 

With `bfind`, the shallower your file is in the directory tree, the faster it
will be printed. This is ideal for the above use case.

# Usage

`bfind [path1] [path2]...`

`bfind` does not implement any options (pull requests welcome)

# Building

Run `make` in the project's directory. Make sure you have ocaml installed, and
that `ocamlopt` is in your $PATH.

# Output Comparison

Suppose you have the following directory structure:

```
.
├── a
│   ├── d
│   │   └── e
│   │       ├── f
│   │       │   └── file5.txt
│   │       └── file4.txt
│   └── file1.txt
├── b
│   └── file2.txt
└── c
    └── file3.txt
```

Assuming you have GNU find installed, running `find .` results in:

```
.
./file1.txt
./a
./a/d
./a/d/e
./a/d/e/f
./a/d/e/f/file4.txt
./a/d/e/f/file5.txt
./b
./b/file2.txt
./c
./c/file3.txt
```

And the output of `bfind .` is:

```
.
./c
./b
./a
./file1.txt
./c/file3.txt
./b/file2.txt
./a/d
./a/d/e
./a/d/e/f
./a/d/e/f/file5.txt
./a/d/e/f/file4.txt
```

Notice that the files deepest into the directory structure (file4 and file5)
are printed last.
