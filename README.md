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
