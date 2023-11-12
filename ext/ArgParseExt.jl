module ArgParseExt

using Tryparse

isdefined(Base, :get_extension) ? (using ArgParse) : (using ..ArgParse)

import ArgParse: parse_item_wrapper

for Typ in Tryparse.POSSIBLE_TYPES
  @eval begin
    function ArgParse.parse_item_wrapper(::Type{T}, x::AbstractString) where {T <: $Typ}
      if Tryparse.is_overridden(T)
        return Tryparse.parse(T, x)
      else
        local r::T
        try
          r = ArgParse.parse_item(T, x)
        catch err
          ArgParse.argparse_error("""
                                  invalid argument: $x (conversion to type $T failed; you may need to overload
                                  ArgParse.parse_item; the error was: $err)""")
        end
        return r
      end
    end
  end
end

end
