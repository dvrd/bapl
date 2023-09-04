# Building a programming language

This is my public record of the work done in classpert course on making your own language

## Week 1 - Little Arithmetic Parser
First week is mainly introduction to how lua works and playing around with lpeg (a lua library for PEG parsing)
by creating a grammar to handle numerical computations. Left it with some basic vector operations and factorial as an extra

## Week 2 - Basic interpreter
We start to delve into building an AST from parsing, and compiling

The interpreter now is a bit more intelligent so there is a very simple repl which can now receive files and expressions.
It now allows for basic arithmetic and comparison.

```
# This will execute a file with the compiler
./week-2/repl.lua -f ./week-2/ex1.sel # returns 6 nothing fancy

# You can run the repl by executing it without arguments
./week-2/repl.lua

# Or execute an argument with the `e` flag
./week-2/repl.lua -e "3 + 3" # returns 6 like before

# To enable tracing just pass --trace as a flag
```

## Week 3 - Assignments
This week I started with trying to build a PEG parser in Odin, so far without much success so far, you 
can find it at [my repo](https://github.com/dvrd/pegasus) if you are curious. I reorganized the repository to 
make the language utility executable. I updated my `.zshrc` with the path to the directory and renamed `repl.lua` to `bapl`.

Now you can execute everything like this

```
# This will execute a file with the compiler
bapl -f <somefile>

# You can run the repl by executing it without arguments
bapl

# Or execute an argument with the `e` flag
bapl -e "3 + 3" # returns 6 like before

# To enable tracing just pass --trace as a flag
```

To verify the interpreter is working you can run `bapl --check week-3` and it will run the tests for that week


