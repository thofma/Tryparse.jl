using Tryparse
using Test

tryparse = Tryparse.tryparse
parse = Tryparse.parse
ParseError = Tryparse.ParseError

@testset "Tryparse.jl" begin
  # ParseError

  e = ParseError("test")
  io = IOBuffer()
  Base.showerror(io, e)
  @test String(take!(io)) == "ParseError: test"

  @test_throws ParseError parse("1///1")

  @test Tryparse._tryparse(Int, nothing, false) === nothing

  # Int's
  for T in [Int32, Int, Int128, BigInt]
    for (val, str) in [(-1, "-1"), (1, "1"), (2, "1 + 1"), (-7, "1 - 2^3"), (5, "div(10, 2)"), (12, "2 * 3 * 2")]
      x = tryparse(T, str)
      @test x isa T
      @test x == val
      y = parse(T, str)
      @test y isa T
      @test y == val
    end
  end

  x = tryparse(BigInt, "10^50")
  @test x isa BigInt && x == big(10)^50

  @test tryparse(Int, "1//2") === nothing
  @test_throws ParseError parse(Int, "1//2")
  @test tryparse(Int, "1 + ") === nothing
  @test_throws ParseError parse(Int, "1 + ")
  @test tryparse(Int, "1 + (2 + 3") === nothing
  @test_throws ParseError parse(Int, "1 + (2 + 3")
  @test tryparse(Int, "sin(2)") === nothing
  @test_throws ParseError parse(Int, "sin(2)")

  # Float's
  for T in [Float32, Float64, BigFloat]
    for (val, str) in [(-1.0, "-1.0"), (1, "1"), (2, "1 + 1"), (-7, "1 - 2^3"), (5, "div(10, 2)"), (1, "1.0/1.0"), (12, "2.0 * 3.0 * 2.0")]
      x = tryparse(T, str)
      @test x isa T
      @test x == val
      y = parse(T, str)
      @test y isa T
      @test y == val
    end
  end

  # Rational
  for T in [Rational{Int32}, Rational{Int}, Rational{Int128}, Rational{BigInt}]
    for (val, str) in [(1, "1"), (2, "1 + 1"), (-7, "1 - 2^3"), (5, "10//2"), (12, "2 * 3 * 2"), (3//4, "(3//2)//(2//1)")]
      x = tryparse(T, str)
      @test x isa T
      @test x == val
      y = parse(T, str)
      @test y isa T
      @test y == val
    end
  end

  # Vector
  x = tryparse(Vector{Int}, "[1]")
  @test x isa Vector{Int} && x == [1]
  x = parse(Vector{Int}, "[1]")
  @test x isa Vector{Int} && x == [1]

  x = tryparse(Vector{Int}, "[1,]")
  @test x isa Vector{Int} && x == [1]
  x = parse(Vector{Int}, "[1,]")
  @test x isa Vector{Int} && x == [1]

  x = tryparse(Vector{Int}, "[1,2^10]")
  @test x isa Vector{Int} && x == [1, 2^10]
  x = parse(Vector{Int}, "[1,2^10]")
  @test x isa Vector{Int} && x == [1, 2^10]

  x = tryparse(Vector{BigInt}, "[1,2^100]")
  @test x isa Vector{BigInt} && x == [1, big(2)^100]

  @test tryparse(Vector{Int}, "1") === nothing
  @test_throws ParseError parse(Vector{Int}, "1")
  @test tryparse(Vector{Int}, "[1,2") === nothing
  @test_throws ParseError parse(Vector{Int}, "[1,2")

  @test_throws ParseError parse(Vector{Int}, "[i for i in 1:10]")

  # Tuple
  x = tryparse(Tuple{Int}, "(1,)")
  @test x isa Tuple{Int} && x == (1,)
  x = parse(Tuple{Int}, "(1,)")
  @test x isa Tuple{Int} && x == (1,)

  x = tryparse(Tuple{Int, Int}, "(1,2^10)")
  @test x isa Tuple{Int, Int} && x == (1, 2^10)
  x = parse(Tuple{Int, Int}, "(1,2^10)")
  @test x isa Tuple{Int, Int} && x == (1, 2^10)

  x = tryparse(Tuple{Int, BigInt}, "(1,2^100)")
  @test x isa Tuple{Int, BigInt} && x == (1, big(2)^100)

  @test tryparse(Tuple{Int}, "1") === nothing
  @test_throws ParseError parse(Tuple{Int}, "1")
  @test tryparse(Tuple{Int, Int}, "(1,2") === nothing
  @test_throws ParseError parse(Tuple{Int, Int}, "[1,2")

  # Matrix
  x = tryparse(Matrix{Int}, "[1 2;]")
  @test x isa Matrix{Int} && x == [1 2;]
  x = parse(Matrix{Int}, "[1 2;]")
  @test x isa Matrix{Int} && x == [1 2;]

  x = tryparse(Matrix{Int}, "[1 2; 3 4; 5 6]")
  @test x isa Matrix{Int} && x == [1 2; 3 4; 5 6]
  x = parse(Matrix{Int}, "[1 2; 3 4; 5 6]")
  @test x isa Matrix{Int} && x == [1 2; 3 4; 5 6]

  x = tryparse(Matrix{Int}, "[1 2; 3+3 4; 5 6]")
  @test x isa Matrix{Int} && x == [1 2; 6 4; 5 6]
  x = parse(Matrix{Int}, "[1 2; 3+3 4; 5 6]")
  @test x isa Matrix{Int} && x == [1 2; 6 4; 5 6]

  x = tryparse(Matrix{Int}, "[1 2; 3+3 4; 5 6]")
  @test x isa Matrix{Int} && x == [1 2; 6 4; 5 6]
  x = parse(Matrix{Int}, "[1 2; 3+3 4; 5 6]")
  @test x isa Matrix{Int} && x == [1 2; 6 4; 5 6]

  x = tryparse(Matrix{BigInt}, "[1 2; 2^100 4; 5 6]")
  @test x isa Matrix{BigInt} && x == [1 2; big(2)^100 4; 5 6]
  x = parse(Matrix{BigInt}, "[1 2; 2^100 4; 5 6]")
  @test x isa Matrix{BigInt} && x == [1 2; big(2)^100 4; 5 6]

  @test tryparse(Matrix{Int}, "[1, 2; 1, 2, 3]") === nothing
  @test_throws ParseError parse(Matrix{Int}, "[1, 2; 1, 2, 3]")
  @test_throws ParseError parse(Matrix{Int}, "[1  2; 1  2  3]")
  @test tryparse(Matrix{Int}, "[1, 2]") === nothing
  @test_throws ParseError parse(Matrix{Int}, "[1, 2]")

  # UnitRange
  x = tryparse(UnitRange{Int}, "1:0")
  @test x isa UnitRange{Int} && x == 1:0
  x = parse(UnitRange{Int}, "1:0")
  @test x isa UnitRange{Int} && x == 1:0

  x = tryparse(UnitRange{Int}, "-1:2^3")
  @test x isa UnitRange{Int} && x == -1:2^3
  x = parse(UnitRange{Int}, "-1:2^3")
  @test x isa UnitRange{Int} && x == -1:2^3

#  x = tryparse(UnitRange{Float64}, "1.0:0.0")
#  @test x isa UnitRange{Float64} && x == 1.0:0.0
#  x = parse(UnitRange{Float64}, "1.0:0.0")
#  @test x isa UnitRange{Float64} && x == 1.0:0.0
#
#  x = tryparse(UnitRange{Float64}, "-1.0:2.0^3")
#  @test x isa UnitRange{Float64} && x == -1.0:2.0^3
#  x = parse(UnitRange{Float64}, "-1.0:2.0^3")
#  @test x isa UnitRange{Float64} && x == -1.0:2.0^3

  @test tryparse(UnitRange{Int}, "1:0:0") === nothing
  @test_throws ParseError parse(UnitRange{Int}, "1:0:0")
  @test tryparse(UnitRange{Int}, "[1,2]") === nothing
  @test_throws ParseError parse(UnitRange{Int}, "[1,2]")
  @test tryparse(UnitRange{Int}, "1.2:3.0") === nothing
  @test_throws ParseError parse(UnitRange{Int}, "1.2:3.0")
  @test tryparse(UnitRange{Int}, "1:3:2") === nothing
  @test_throws ParseError parse(UnitRange{Int}, "1:3:2")

  # StepRange
  
  x = tryparse(StepRange{Int}, "1:2:5")
  @test x isa StepRange{Int} && x == 1:2:5
  x = parse(StepRange{Int}, "1:2:5")
  @test x isa StepRange{Int} && x == 1:2:5

  x = tryparse(StepRange{Int}, "-1:2^3:100")
  @test x isa StepRange{Int} && x == -1:2^3:100
  x = parse(StepRange{Int}, "-1:2^3:100")
  @test x isa StepRange{Int} && x == -1:2^3:100

#  x = tryparse(UnitRange{Float64}, "1.0:0.0")
#  @test x isa UnitRange{Float64} && x == 1.0:0.0
#  x = parse(UnitRange{Float64}, "1.0:0.0")
#  @test x isa UnitRange{Float64} && x == 1.0:0.0
#
#  x = tryparse(UnitRange{Float64}, "-1.0:2.0^3")
#  @test x isa UnitRange{Float64} && x == -1.0:2.0^3
#  x = parse(UnitRange{Float64}, "-1.0:2.0^3")
#  @test x isa UnitRange{Float64} && x == -1.0:2.0^3

  @test tryparse(StepRange{Int}, "1:0") === nothing
  @test_throws ParseError parse(StepRange{Int}, "1:0")
  @test tryparse(StepRange{Int}, "[1,2]") === nothing
  @test_throws ParseError parse(StepRange{Int}, "[1,2]")
  @test tryparse(StepRange{Int}, "1.2:3.0:5.0") === nothing
  @test_throws ParseError parse(StepRange{Int}, "1.2:3.0:5.0")

  # Overriding
  
  @test get(Tryparse.TRYPARSE_OVERRIDE, Int, false) == false
  @test Tryparse.is_overridden(Int) == false
  Tryparse.tryparse_set_override(true, Int)
  @test Tryparse.TRYPARSE_OVERRIDE[Int] == true
  Tryparse.@unoverride Int
  @test Tryparse.TRYPARSE_OVERRIDE[Int] == false
  @test Tryparse.is_overridden(Int) == false
  @test_throws ErrorException Tryparse.@override(Array)
  Tryparse.@override_base BigInt
  @test Base.tryparse(BigInt, "2^2") == 4
  Tryparse.@override_base 
end

# 

_with_argparse = false

push!(Base.LOAD_PATH, "@v#.#")

try
  using ArgParse
  @info("Found ArgParse. Testing extension functionality")
  global _with_argparse = true
catch
  @info("Did not find ArgParse.")
end

if _with_argparse
  @testset "ArgParse" begin
    @test_throws ArgParseError ArgParse.parse_item_wrapper(Matrix{Int}, "[1 2; 3 4]")
    Tryparse.@override Matrix{Int}
    ArgParse.parse_item_wrapper(Matrix{Int}, "[1 2; 3 4]") == [1 2; 3 4]
    Tryparse.@unoverride Matrix{Int}
    @test_throws ArgParseError ArgParse.parse_item_wrapper(Matrix{Int}, "[1 2; 3 4]")

    @test_throws ArgParseError ArgParse.parse_item_wrapper(Int, "1+3-2")
    Tryparse.@override Int
    @test ArgParse.parse_item_wrapper(Int, "1+3-2") == 2
    Tryparse.@unoverride
    @test !Tryparse.is_overridden(Int)
  end
end

try
  using ArgMacros
  @info("Found ArgMacros. Testing extension functionality")
  global _with_argmacros = true
catch
  @info("Did not find ArgMacros.")
end

if _with_argmacros
  @testset "ArgMacros" begin
    ArgMacros._quit_try_help(message::String) = throw(ParseError(""))
    @test_throws ParseError ArgMacros._converttype!(Matrix{Int}, "[1 2; 3 4]", "a")
    Tryparse.@override Matrix{Int}
    ArgMacros._converttype!(Matrix{Int}, "[1 2; 3 4]", "a") == [1 2; 3 4]
    Tryparse.@unoverride Matrix{Int}
    @test_throws ParseError ArgMacros._converttype!(Matrix{Int}, "[1 2; 3 4]", "a")

    @test_throws ParseError ArgMacros._converttype!(Int, "1+3-2", "a")
    Tryparse.@override Int
    @test ArgMacros._converttype!(Int, "1+3-2", "a") == 2
    Tryparse.@unoverride
  end
end

try
  using Nemo
  @info("Found Nemo. Testing extension functionality")
  global _with_nemo = true
catch
  @info("Did not find Nemo.")
end

if _with_nemo
  @testset "Nemo" begin
    x = tryparse(ZZRingElem, "10^50")
    @test x isa ZZRingElem && x == big(10)^50

    @test tryparse(ZZRingElem, "1//2") === nothing
    @test_throws ParseError parse(ZZRingElem, "1//2")
    @test tryparse(ZZRingElem, "1 + ") === nothing
    @test_throws ParseError parse(ZZRingElem, "1 + ")
    @test tryparse(ZZRingElem, "1 + (2 + 3") === nothing
    @test_throws ParseError parse(ZZRingElem, "1 + (2 + 3")
    @test tryparse(ZZRingElem, "sin(2)") === nothing
    @test_throws ParseError parse(ZZRingElem, "sin(2)")

    for (val, str) in [(1, "1"), (2, "1 + 1"), (-7, "1 - 2^3"), (5, "10//2"), (12, "2 * 3 * 2"), (3//4, "(3//2)//(2//1)")]
      x = tryparse(QQFieldElem, str)
      @test x isa QQFieldElem
      @test x == val
      y = parse(QQFieldElem, str)
      @test y isa QQFieldElem
      @test y == val
    end

    @test tryparse(QQFieldElem, "sin(2)") === nothing
    @test_throws ParseError parse(QQFieldElem, "sin(2)")
  end
end

