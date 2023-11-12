module ArgMacrosExt

using Tryparse

isdefined(Base, :get_extension) ? (using ArgMacros) : (using ..ArgMacros)

import ArgMacros: _converttype!

for Typ in Tryparse.POSSIBLE_TYPES
  @eval begin
    function ArgMacros._converttype!(::Type{T}, s::String, name::String) where {T <: $Typ}
      if Tryparse.is_overridden(T)
        return Tryparse.parse(T, s)
      else
        try
          if T <: Number
            # Allow floating point value to be passed to Int argument
            return T(parse(Float64, s)::Float64)
          else
            return T(s)
          end
        catch
          ArgMacros._quit_try_help("Invalid type for argument $name")
        end
      end
    end
  end
end

end
