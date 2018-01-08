defmodule Klambda.Primitives do
  alias Klambda.Env
  alias Klambda.Reader.Eval

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

      if: fn(condition) -> fn(consequent) -> fn(alternative) ->
        if condition, do: consequent, else: alternative
      end end end,

      set: fn(sym) -> fn(val) ->
        :ok = Env.define_global(sym, val)
        val
      end end,

      "trap-error": fn(body) -> fn(handler) ->
        try do
          body
        catch
          {:"simple-error", _message} -> Eval.eval([handler, body])
        end
      end end,

      "simple-error": fn(message) -> throw {:"simple-error", message} end,

      "error-to-string": fn({:"simple-error", message}) -> message end
    }
  end
end
