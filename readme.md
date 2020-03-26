# cminus compiler

This is the compiler for the cminus language (a simple, c-like language) created as a part of my compilers class at NMSU in 2017.

### You'll need the following to be installed to use it:
- `nasm`
- `flex` / `lex`
- `bison` / `yacc`
- `sasm`

### To Compile (the cminus compiler)
```
make
```

### To Compile (some cminus code)
```
cminus < mycode.cm
```
Run `cminus -help` for more options.

The compiler outputs code in x64 Assembly. The simplest way to run is to load it into SASM (Make sure the settings in SASM are set for NASM x64).

### In this repository

- **sample/**: Sample snippets of cminus code and corresponding Assembly provided by instructor.
- **test/**: Snippets of cminus code for testing.
- **out.ams**: Example of compiler output. Generated from `test/testmax.cm`.