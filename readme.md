# cminus compiler

This is the compiler for the cminus language (a simple, c-like language) created in compilers class.

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