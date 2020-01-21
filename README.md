# bfind

`bfind` is similar to the Unix `find(1)` command except it searches breadth
first instead of depth first. A breadth first search is useful if you are
searching for a file with something like:

`find ~ | grep myfile`

If your $HOME has heavily nested directories the above command could take some
time to print any output. Using `bfind` in this example, the shallower your
file is in the directory tree the faster it will be printed.

## Dependencies

- [LuaFileSystem](https://keplerproject.github.io/luafilesystem/),

## Usage

`bfind.lua [path]`

`bfind.lua` does not implement any options (pull requests welcome)

## Output Comparison

Suppose you have the following directory structure:

```
.
├── a
│   └── d
│       └── e
│           └── f
│               ├── file4.txt
│               └── file5.txt
├── b
│   └── file2.txt
├── c
│   └── file3.txt
│
└── file1.txt

```

Assuming you have GNU find installed, running `find .` results in something like:

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

And the output of `bfind.lua .` is:

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

Notice that files deepest into the filesystem (file4 and file5) are printed
last.
