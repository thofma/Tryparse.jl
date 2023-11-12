module NemoExt

using Tryparse

isdefined(Base, :get_extension) ? (using Nemo) : (using ..Nemo)

function Tryparse._tryparse(::Type{fmpz}, ex, x)
  y = Tryparse._tryparse(BigInt, ex, x)
  if !(y isa BigInt) || (y === nothing)
    if !x
      return nothing
    else
      throw(Tryparse.ParseError("Cannot convert \"$(ex)\" to type $(fmpz)"))
    end
  end
  return Nemo.ZZ(y)::fmpz
end

function Tryparse._tryparse(::Type{fmpq}, ex, x)
  y = Tryparse._tryparse(Rational{BigInt}, ex, x)
  if !(y isa Rational{BigInt}) || (y === nothing)
    if !x
      return nothing
    else
      throw(Tryparse.ParseError("Cannot convert \"$(ex)\" to type $(fmpq)"))
    end
  end
  return Nemo.QQ(y)::fmpq
end

end
