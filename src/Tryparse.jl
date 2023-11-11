module Tryparse

using PackageExtensionCompat

function __init__()
    @require_extensions
end

struct ParseError <: Exception
  msg
end

function Base.showerror(io::IO, err::ParseError)
  print(io, "ParseError: ")
  print(io, err.msg)
end

# Own little parse helper to beautify the error message
function parse(s)
  try
    ex = Meta.parse(s, raise = true)
    return ex
  catch e
    @assert e isa Meta.ParseError
    rethrow(ParseError("Error while parsing string \"$(s)\": $(e.msg)"))
  end
end

# Parse expression for numbers
function tryparse(::Type{T}, s::Union{SubString, String}) where {T <: Number}
  ex = parse(s)
  r = _tryparse(T, ex, false)
  r === nothing && return r
  # there is a chance, that this is an Int or some other number
  try
    s = T(r)
    return s
  catch e
    @assert e isa InexactError # else rethrow
    return nothing
  end
end

function _tryparse(::Type{T}, ex, maythrow = true) where {T <: Number}
  if ex === nothing
    return nothing
  end
  if ex isa T || ex isa Number # parse also 2.0^3
    try
      return T(ex)
    catch e
      if !maythrow
        return nothing
      end
      @assert e isa InexactError # else rethrow(e)
      rethrow(ParseError("Cannot convert \"$(ex)\" to type $(T)"))
    end
  else
    !(ex isa Expr) && maythrow && throw(ParseError("Unexpected error. Please file a bug report"))
    if ex.head === :call
      if ex.args[1] === :+
        return reduce(+, _tryparse(T, ex.args[i], maythrow) for i in 2:length(ex.args), init = zero(T))
      elseif ex.args[1] === :-
        return reduce(-, _tryparse(T, ex.args[i], maythrow) for i in 2:length(ex.args), init = zero(T))
      elseif ex.args[1] === :*
        return reduce(*, _tryparse(T, ex.args[i], maythrow) for i in 2:length(ex.args), init = one(T))
      else
        #for (sym, fun) in [(:^, ^), (:/, /), (://, //), (:%, %), (:div, div)]
        for (sym, fun) in [(:^, ^), (:/, /), (://, //), (:%, %), (:div, div)]
          if ex.args[1] === sym
            return fun(_tryparse(T, ex.args[2], maythrow), _tryparse(T, ex.args[3], maythrow))
          end
        end
        maythrow && throw(ParseError("Unknown call \"$(ex.args[1])\" while parsing $(T)"))
      end
    end
  end
  maythrow && throw(ParseError("Unknown syntax \"$(ex)\" while parsing $(T)"))
  return nothing
end

# Vector
function tryparse(::Type{Vector{T}}, s::Union{SubString, String}) where {T}
  ex = parse(s)
  r = _tryparse(Vector{T}, ex, false)
  # there is a chance, that this is an Int
  return r
end

function _tryparse(::Type{Vector{T}}, ex, maythrow = true) where {T}
  if ex isa Expr
    if ex.head === :vect
      return T[_tryparse(T, a, maythrow) for a in ex.args]
    elseif ex.head === :comprehension
      maythrow && throw(ParseError("List comprehension not supported."))
    end
  end
  maythrow && throw(ParseError("Unkown syntax for vector construction. Please use \"[...]\"."))
  return nothing
end

# Tuple
function tryparse(S::Type{<:Tuple}, s::Union{SubString, String}) 
  ex = parse(s)
  r = _tryparse(S, ex, false)
  # there is a chance, that this is an Int
  return r
end

function _tryparse(S::Type{<:Tuple}, ex, maythrow = true) 
  fT = fieldtypes(S)
  if ex isa Expr
    if ex.head === :tuple
      return ntuple(i -> _tryparse(fT[i], ex.args[i], maythrow), length(ex.args))
    end
  end
  maythrow && throw(ParseError("Unkown syntax for tuple construction. Please use \"(...)\"."))
  return nothing
end

# Matrix
function tryparse(::Type{Matrix{T}}, s::Union{SubString, String}) where {T}
  ex = parse(s)
  r = _tryparse(Matrix{T}, ex, false)
  # there is a chance, that this is an Int
  return r
end

function _tryparse(::Type{Matrix{T}}, ex, maythrow = true) where {T}
  if ex isa Expr
    if ex.head === :vcat
      nr = length(ex.args)
      nc = length(ex.args[1].args)
      if any(a -> length(a.args) != nc, ex.args)
        maythrow && throw(ParseError("Unequal number of columns"))
        return nothing
      end
      M = Matrix{T}(undef, nr, nc)
      for (i, a) in enumerate(ex.args)
        a.head !== :row && maythrow && throw(ParseError("Unexpected error. Please file a bug report"))
        for (j, v) in enumerate(a.args)
          M[i, j] = _tryparse(T, v, maythrow)
        end
      end
      return M
    end
  end
  maythrow && throw(ParseError("Unkown syntax for matrix construction. Please use \"[...;...]\"."))
  return nothing
end

# UnitRange

function tryparse(::Type{UnitRange{T}}, s::Union{SubString, String}) where {T}
  ex = parse(s)
  r = _tryparse(UnitRange{T}, ex, false)
  return r
end

function _tryparse(::Type{UnitRange{T}}, ex, maythrow = true) where {T}
  if ex isa Expr
    if ex.head === :call
      if ex.args[1] === :(:)
        if length(ex.args) == 3
          a = _tryparse(T, ex.args[2], maythrow)
          a === nothing && return a
          b = _tryparse(T, ex.args[3], maythrow)
          b === nothing && return b
          return a:b
        end
      end
    end
  end
  maythrow && throw(ParseError("Unkown syntax \"$(ex)\" for unit range construction. Please use \"...:...\"."))
  return nothing
end

# Steprange
function tryparse(::Type{StepRange{T}}, s::Union{SubString, String}) where {T}
  ex = parse(s)
  r = _tryparse(StepRange{T}, ex, false)
  return r
end

function _tryparse(::Type{StepRange{T}}, ex, maythrow = true) where {T}
  if ex isa Expr
    if ex.head === :call
      if ex.args[1] === :(:)
        if length(ex.args) == 4
          a = _tryparse(T, ex.args[2], maythrow)
          a === nothing && return a
          b = _tryparse(T, ex.args[3], maythrow)
          b === nothing && return b
          c = _tryparse(T, ex.args[4], maythrow)
          c === nothing && return c
          return a:b:c
        end
      end
    end
  end
  maythrow && throw(ParseError("Unkown syntax \"$(ex)\" for step range construction. Please use \"...:...:...\"."))
  return nothing
end

# parse
function parse(T::Type, s)
  r = _tryparse(T, parse(s), true)
  if T <: Number
    try
      return T(r)
    catch e
      if e isa InexactError
        rethrow(ParseError("Cannot convert \"$(s)\" to type $(T)"))
      else
        rethrow(e)
      end
    end
  else
    return r
  end
end

#
const POSSIBLE_TYPES = [Number, Vector, Tuple, Matrix, UnitRange, StepRange]

const try_parse_override = Dict{Any, Any}()

macro override(s...)
  args = []
  if length(s) == 0
    return :(tryparse_override())
  end
  for i in 1:length(s)
    push!(args, :(tryparse_override($(s[i]))))
  end
  return Expr(:block, args...)
end

function tryparse_override(type::Type)
  return tryparse_override([type])
end

function tryparse_override(types = POSSIBLE_TYPES)
  for T in types
    if all(!(T <: S) for S in POSSIBLE_TYPES)
    error("""
          Cannot override parsing for type $(T).
          Possible types are $(POSSIBLE_TYPES).
          """)
  end

    try_parse_override[T] = true
  end
  nothing
end

is_overwritten(T) = any(T <: S for (S, fl) in try_parse_override if fl)

################################################################################
#
#  Overriding Base.tryparse
#
################################################################################

macro override_base(types...)
  if length(types) == 1
    types = [types[1]]
  elseif length(types) == 0
    types = [Symbol(T) for T in Tryparse.POSSIBLE_TYPES]
  end
  args = []
  for type in types
    push!(args, esc(:(Base.tryparse(::Type{S}, y::AbstractString) where {S <: $type} = Tryparse.tryparse(S, y))))
  end
  return Expr(:block, args...)
end

end
