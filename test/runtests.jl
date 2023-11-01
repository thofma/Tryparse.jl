using Tryparse
using Test

tryparse = Tryparse.tryparse
parse = Tryparse.parse
ErrorParse = Tryparse.ErrorParse

@testset "Tryparse.jl" begin
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
  @test_throws ErrorParse parse(Int, "1//2")
  @test tryparse(Int, "1 + ") === nothing
  @test_throws ErrorParse parse(Int, "1 + ")
  @test tryparse(Int, "1 + (2 + 3") === nothing
  @test_throws ErrorParse parse(Int, "1 + (2 + 3")
  @test tryparse(Int, "sin(2)") === nothing
  @test_throws ErrorParse parse(Int, "sin(2)")

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
  @test_throws ErrorParse parse(Vector{Int}, "1")
  @test tryparse(Vector{Int}, "[1,2") === nothing
  @test_throws ErrorParse parse(Vector{Int}, "[1,2")

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
  @test_throws ErrorParse parse(UnitRange{Int}, "1:0:0")
  @test tryparse(UnitRange{Int}, "[1,2]") === nothing
  @test_throws ErrorParse parse(UnitRange{Int}, "[1,2]")
  @test tryparse(UnitRange{Int}, "1.2:3.0") === nothing
  @test_throws ErrorParse parse(UnitRange{Int}, "1.2:3.0")
  @test tryparse(UnitRange{Int}, "1:3:2") === nothing
  @test_throws ErrorParse parse(UnitRange{Int}, "1:3:2")

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
  @test_throws ErrorParse parse(StepRange{Int}, "1:0")
  @test tryparse(StepRange{Int}, "[1,2]") === nothing
  @test_throws ErrorParse parse(StepRange{Int}, "[1,2]")
  @test tryparse(StepRange{Int}, "1.2:3.0:5.0") === nothing
  @test_throws ErrorParse parse(StepRange{Int}, "1.2:3.0:5.0")
end
