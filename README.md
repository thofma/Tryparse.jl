# Tryparse

---

*Parsing things that should be parsable without eval*

---

## Status


[![Build Status](https://github.com/thofma/Tryparse.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/thofma/Tryparse.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/thofma/Tryparse.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thofma/Tryparse.jl)
[![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/T/Tryparse.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/T/Tryparse.html)

#### Table of contents

- [Synopsis](#synopsis)
- [Installation](#installation)
- [Usage](#usage)
- [Notable difference to the REPL experience](#notable-difference-to-the-repl-experience)
- [Command line argument parsing](#command-line-argument-parsing)
  - [ArgParse](#argparse)
  - [ArgMacros](#argmacros)
  - [Comonicon](#comonicon)
- [FAQ](https://github.com/thofma/#faq)
  - [Does this package use eval?](#does-this-package-use-eval)


## Synopsis

When working interactively or interacting with other sources of data, one can find oneself in a situation, where one needs to construct Julia objects from a given string. While this is in general a hard problem, in practice it is more managable, as the types are restricted to a small set, including numbers, arrays or tuples. For number types `Base.tryparse` provides this functionality, as long as the string is a literal interger.
Here we provide a function `Tryparse.tryparse`, which does the same as `Base.tryparse`, but allows (for number types) a wider range of basic types as well expressions. Here is a short example, which illustrates the functionality:

```julia
julia> Base.tryparse(Int, "2 + 3^2 - 2 * 3") === nothing # this means, parsing could not be done
true

julia> Tryparse.tryparse(Int, "2 + 3^2 - 2 * 3")
5
```

The package has a seamless integration with ArgParse.jl, ArgMacros.jl and Comonicon.jl to allow for ergonomic command line argument parsing. See (#command-line-argument-parsing) for details.

## Installation

Since Tryparse.jl is a registered package, it can be simply installed as follows:
```julia
julia> using Pkg; Pkg.install("Tryparse")
```

## Usage

The package provides two functions:
```julia
Tryparse.tryparse(T::Type, x::String)
```
> Try to parse `x` as an object of type `T`. If this is not possible, the function returns `nothing`.

```julia
Tryparse.parse(T::Type, x::String)
```
> Try to parse `x` as an object of type `T`. If this is not possible, an error of type `Tryparse.ParseError` is thrown.

Table of supported types as well as allowed syntax.

| Type     | Snytax | Example |
-----------|--------|-----|
| `<: Number` | Any arithmetic expression (may contain `^`) | `Tryparse.tryparse(BigInt, "10^100") == big(10)^100` |
| `<: Tuple` | Expressions of the form `(...)` | `Tryparse.tryparse(Tuple{Int, Float64}, "(1, 1.2)" == (1, 1.2)` |
| `<: Vector` | Expressions of the form `[...]` | `Tryparse.tryparse(Vector{Int}, "[2,1+1,3]") == [2,2,3]` |
| `<: Matrix` | Expressions of the form `[...;...]` | `Tryparse.tryparse(Matrix{Int}, "[1 2; 3 4]") == [1 2; 3 4]` |
| `<: UnitRange` | Expressions of the form `...:...` | `Tryparse.tryparse(UnitRange{Int}, "1:10") == 1:10` |
| `<: StepRange` | Expressions of the form `...:...:...` | `Tryparse.tryparse(StepRange{Int}, "2:-1:-10") == 2:-1:-10` |

The types can be nested arbitrarily:

```julia
julia> Tryparse.tryparse(Vector{Matrix{Int}}, "[[2 2; 3 1], [1 2; 3 4]]")
2-element Vector{Matrix{Int64}}:
 [2 2; 3 1]
 [1 2; 3 4]
```

## Notable difference to the REPL experience

In almost all cases, executing `Tryparse.tryparse(T, x)` will yield the same result as entering `x` in the REPL and hitting enter. One situation, where this is not the case, is related to arithmetic expressions and overflow. The function `Tryparse.tryparse` will always first parse all literal numbers and then evaluate the expression. For example:

```julia
julia> BigInt(2^64)
0

julia> Tryparse.tryparse(BigInt, "2^64")
18446744073709551616
```

This choice of behavior is on purpose, to make working with command line arguments less painful.

## Command line argument parsing

The reason this package exists is parsing of command line arguments for julia scripts. Command line scripts are invokved in the form

```bash
bla@home> julia script.jl arg1 arg2
```

In this situation, inside `script.jl`, the arguments are available only as strings and thus need to be processed. Here is where `Tryparse.tryparse` comes into play.

Similarly, if one uses ArgParse.jl, ArgMacros.jl or Comonicon.jl (those packages are highly recommended!), this looks like
```bash
bla@home> julia script.jl --opt1=arg1 --opt2=arg2
```
and one can specifiy what the types of `arg1` and `arg2`. But this will work only for types and strings, for which `Base.tryparse` respectively `Base.parse` works. For example, out of the box
```bash
bla@home> julia script.jl --opt1="10^10" --opt2="[2, 3]"
```
would not work, whereas this is possible with `Tryparse`. We illustrate how to use `Tryparse` together with [ArgParse.jl](https://github.com/carlobaldassi/ArgParse.jl), [ArgMacros.jl](https://github.com/zachmatson/ArgMacros.jl) and [Comonicon.jl](https://github.com/comonicon/Comonicon.jl).

### ArgParse

Enabling parsing of command line arguments is straight forward for ArgParse.jl. Just add (one of) the following lines to your script:

```
using ArgParse
using Tryparse

Tryparse.@override Int Float64 # will intercept command line argument parsing of Int and Float64
Tryparse.@override             # will intercept all command line argument parsing
```

<details>
<summary>Example `script_tryparse.jl`:</summary>

```julia
using ArgParse, TryParse

Tryparse.@override Int Matrix{Int}

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table! s begin
    "--opt1"
        help = "an option with an argument"
        arg_type = Int
        default = 0
    "--opt2", "-o"
        help = "another option with an argument"
        arg_type = Matrix{Int}
        default = [0 0; 0 0]
    end
    return parse_args(s)
end

function main()
    parsed_args = parse_commandline()
    println("Parsed args:")
    for (arg,val) in parsed_args
        println("  $arg  =>  $val, $(typeof(val))")
    end
end
main()
```
</details>

Executing this yields:
```bash
bla@home> julia script_tryparse.jl --opt1="1+2^10" --opt2="[1 2; 3 4]"
Parsed args:
  opt1  =>  1025, Int64
  opt2  =>  [1 2; 3 4], Matrix{Int64}
```

### ArgMacros

Enabling parsing of command line arguments is straight forward for ArgMacros.jl. Just add (one of) the following lines to your script:

```
using ArgParse
using Tryparse

Tryparse.@override Int Float64 # will intercept command line argument parsing of Int and Float64
Tryparse.@override             # will intercept all command line argument parsing
```

<details>
<summary>Example `script_argmacros.jl`:</summary>

```julia
using ArgMacros, Tryparse

Tryparse.@override Int Float64

function main()
    @inlinearguments begin
        @positionalrequired Int x
        @positionaloptional Float64 z
    end

    println(x, " ", typeof(x))
    println(z, " ", typeof(z))
end

main()
```
</details>

Executing this yields:
```bash
bla@home> julia script_argmacros.jl "1+2^10" "1.1^2"
1025 Int64
1.2100000000000002 Float64
```

### Comonicon

Enabling parsing of command line arguments for Comonicon is a bit more brittle. To do this, we invoke `Tryparse.@override_base`. Note that this overrides the behavior of `Base.parse` and does not work for `Float64`.

```
using Comonicon
using Tryparse

Tryparse.@override_base_base Matrix{Int} BigInt # will intercept command line parsing of Matrix{Int} and BigInt
```

<details>
<summary>Example `script_comonicon.jl`:</summary>

```julia
using Comonicon, Tryparse

Tryparse.@override_base Matrix{Int} BigInt

@main function main(; opt1::Matrix{Int}=[0 0; 0 0],
opt2::BigInt=big(2))
    println("Parsed args:")
    println("opt1=>", opt1)
    println("opt2=>", opt2)
end
```
</details>

Executing this yields:
```bash
bla@home> julia script_comonicon.jl --opt1="[1 2; 3 4]" --opt2="2^100"
Parsed args:
opt1=>[1 2; 3 4]
opt2=>1267650600228229401496703205376
```

## FAQ

### Does this package use `eval`?

No. This is certified to be a `eval`-free.
