isalis
======

An ls alike command for listing/classifying aliases and bad aliases from a terminal prompt in OS X

The main objective is to provide the functionality below. The objective for sharing the code
is to provide an easy acces point for people who want to make and share shell-tools that plays
well with alias files on OS X.

Enjoy.

Usage: isalis [options] [1..n file arguments or from stdin; one file  on each line.]

Options
-------
  All output options are mutually exclusive, the last one takes effect.

  isalis [- -huncVdrvb]
  isalis [ --help,--usage,--normal,--copyright
-          --version,--delimiter,--report,--verbose,--broken ]

Examples
--------
  isalis file1
  Returns the original item of file1 if it exists, great for the cd command.

  cat flist |isalis 
  prints the paths of the original items given from any aliases from stdin

  cat flist |isalis -r
  Prints the original items of all aliases found, or broken, to the right
  of the filename.

  cat flist | isalis  -v
  Mirrors the original listings but adds a column with any aliases, or prints
  BROKEN in the same column.

  isalis --broken f1 f2 f3 f4 ...
  prints all broken aliases found in the files given on the command line.

Explanation of the options
--------------------------

  -h,--help:      Shows this help and quits.

  -u,--usage:     Shows this help and quits.

  -n,--normal:    Shows the alias if found in file-argument given.
                  This is the  same as giving no option.

  -d,--delimiter: Sets the delimiter, for separating path and alias.

  -c,--copyright: Prints out a copyright notice.

  -v,--version:   Prints out the version of isalis.

  -r,--report:    Prints a report containing every alias found in the file
                  arguments, and if they are bad.  Broken aliases are
				  printed onto stderr.

                  ----------------------------------------------------------------

                  [original filename][ tab (\t)][ the alias  (or   BROKEN ALIAS)] 

  -v,--verbose:   Normal files found  are added on separate lines crohnologically
                  with the output from --report.

                  ---------------------------------------------------------------

                  [original filename][ tab (\t)][ the alias  (or   BROKEN ALIAS)] 
                  [regular filename ]
                  [...]

  -b,--broken:    Shows original filenames of all broken aliases to stdout.
                  And nothing more.

                  ---------------------------------------------------------------

                  [original filename]

Error codes
-----------

Single file mode

    0: An alias that was correct was found.
    1: An alias wasn't found.
    2: Is an operator error.
    3: Is a broken alias.
    4: Internal program error.

Multi file mode (Batch).

    0: At least one alias file was found and none with a broken alias was found.
    1: Not a single alias file was found.
    3: At least one alias that was broke were found.
    4: Internal program error.
