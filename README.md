# Tryparse

---

*When all you want is just to parse stuff*

---

## Status


[![Build Status](https://github.com/thofma/Tryparse.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/thofma/Tryparse.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/thofma/Tryparse.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/thofma/Tryparse.jl)
[![PkgEval](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/T/Tryparse.svg)](https://JuliaCI.github.io/NanosoldierReports/pkgeval_badges/T/Tryparse.html)

#### Table of contents

## Synopsis

When working interactively or interacting with other sources of data, one can find oneself in a situation, where one needs to construct Julia objects from a given string. While this is in general a hard problem, in practice it is more managable, as the types are restricted to a small set, including numbers, arrays or tuples. For number types `Base.tryparse` provides this functionality, as long as the string is a literal interger.
Here we provide a function `Tryparse.tryparse`, which does the same as `Base.tryparse`, but allows (for number types) a wider range of basic types as well expressions. Here is a short example, which illustrates the functionality:

```julia
julia> Base.tryparse(Int, "2 + 3^2 - 2 * 3") === nothing # this means, parsing could not be done
true

julia> Tryparse.tryparse(Int, "2 + 3^2 - 2 * 3")
5
```

## Installation

Since Tally.jl is a registered package, it can be simply installed as follows:
```julia
julia> using Pkg; Pkg.install("Tally")
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
| `<: Number` | Any arithmetic expression involving `^` | `Tryparse.tryparse(BigInt, "10^100") == big(10)^100` |
| `<: Tuple` | Expressions of the form `(...)` | `Tryparse.tryparse(Tuple{Int, Float64}, "(1, 1.2)" == (1, 1.2)` |
| `<: Vector` | Expressions of the form `[...]` | `Tryparse.tryparse(Vector{Int}, "[2,1+1,3") == [2,2,3]` |
| `<: Matrix` | Expressions of the form `[...;...]` | `Tryparse.tryparse(Matrix{Int}, "[1 2; 3 4]") == [1 2; 3 4]` |
| `<: UnitRange` | Expressions of the form `...:...` | `Tryparse.tryparse(UnitRange{Int}, "1:10") == 1:10` |
| `<: StepRange` | Expressions of the form `...:...:...` | `Tryparse.tryparse(StepRange{Int}, "2:-1:-10") == 2:-1:-10` |

the types can be nested arbitrarily:

```julia
julia> Tryparse.tryparse(Vector{Matrix{Int}}, "[[2 2; 3 1], [1 2; 3 4]]")
2-element Vector{Matrix{Int64}}:
 [2 2; 3 1]
 [1 2; 3 4]
```

## Notable difference to the REPL experience

In almost all cases, executing `Tryparse.tryparse(T, x)` will yield the same result as entering `x` in the REPL and hitting enter. One situation where this is not the case are related to arithmetic expressions and overflow, since `Tryparse.tryparse` will always first parse all literal numbers and then evaluate the expression. For example:

```julia
julia> 2^64
0

julia> Tryparse.tryparse(BigInt, "2^64")
18446744073709551616
```

This choice of behavior is on purpose, see ....

## Command line argument parsing

Situations where one needs to parse strings as julia objects are interaction with external ressources, like parsing of command line arguments. Command line scripts are invokved in the form

```bash
/path> julia script.jl arg1 arg2
```

In this situation, inside `script.jl` are available only as strings and thus need to be processed. Here is where `Tryparse.tryparse` comes into play.

Similarly, if one uses Argparse or Comonicon.jl (both packages are highly recommended!), this looks like
```bash
/path> julia script.jl --opt1=arg1 --opt2=arg2
```
and one can specifiy what the types of `arg1` and `arg2`. But this will work only for types and strings, for which `Base.tryparse` respectively `Base.parse` works. For example, out of the box
```bash
/path> julia script.jl --opt1=10^10 --opt2=[2,3]
```
would not work, whereas this is possible with `Tryparse`.
