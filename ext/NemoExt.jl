module NemoExt

using Tryparse

isdefined(Base, :get_extension) ? (using Nemo) : (using ..Nemo)

function Tryparse._tryparse(::Type{ZZRingElem}, ex, x)
  y = Tryparse._tryparse(BigInt, ex, x)
  if !(y isa BigInt) || (y === nothing)
    if !x
      return nothing
    else
      throw(Tryparse.ParseError("Cannot convert \"$(ex)\" to type $(ZZRingElem)"))
    end
  end
  return Nemo.ZZ(y)::fmpz
end

function Tryparse._tryparse(::Type{QQFieldElem}, ex, x)
  y = Tryparse._tryparse(Rational{BigInt}, ex, x)
  if !(y isa Rational{BigInt}) || (y === nothing)
    if !x
      return nothing
    else
      throw(Tryparse.ParseError("Cannot convert \"$(ex)\" to type $(QQFieldElem)"))
    end
  end
  return Nemo.QQ(y)::fmpq
end

end
