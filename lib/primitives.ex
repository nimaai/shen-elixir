defmodule Klambda.Primitives do
  alias Klambda.Env

  def mapping do
    %{
      +: fn(x) -> fn(y) -> x + y end end,

      -: fn(x) -> fn(y) -> x - y end end,

      *: fn(x) -> fn(y) -> x * y end end,

      /: fn(x) -> fn(y) -> x / y end end,

      number?: &is_number/1,

      >: fn(x) -> fn(y) -> x > y end end,

      <: fn(x) -> fn(y) -> x < y end end,

      >=: fn(x) -> fn(y) -> x >= y end end,

      <=: fn(x) -> fn(y) -> x <= y end end,

      and: fn(x) -> fn(y) -> x and y end end,

      or: fn(x) -> fn(y) -> x or y end end,

      set: fn(sym) ->
        fn(val) ->
          :ok = Env.define_global(sym, val)
          val
        end
      end
    }
  end
end
