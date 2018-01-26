defmodule Klambda.Primitives do
  alias Klambda.Env
  alias Klambda.Reader.Eval
  alias Klambda.Continuation

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

      "trap-error": fn(body) -> fn(handler) ->
        try do
          body
        catch
          {:"simple-error", _message} -> Eval.eval([handler, body])
        end
      end end,

      "simple-error": fn(message) -> throw {:"simple-error", message} end,

      "error-to-string": fn({:"simple-error", message}) -> message end,

      intern: fn(name) -> String.to_atom(name) end,

      set: fn(sym) -> fn(val) ->
        :ok = Env.define_global(sym, val)
        val
      end end,

      value: fn(sym) -> Env.lookup_global(sym) end,

      "string?": fn(arg) -> is_bitstring(arg) end,

      pos: fn(arg) -> fn(n) ->
        unit = String.at(arg, n)
        if is_nil(unit) do
          throw {:error, "String index is out bounds"}
        else
          unit
        end
      end end,

      tlstr: fn(arg) ->
        if String.length(arg) == 0 do
          throw {:error, "Argument is empty string"}
        else
          {_, tlstr} = String.split_at(arg, 1)
          tlstr
        end
      end,

      cn: fn(s1) -> fn(s2) -> s1 <> s2 end end,

      str: fn(arg) ->
        cond do
          is_bitstring(arg) -> "\"" <> arg <> "\""
          [:lambda | _] = arg -> "\"" <> arg <> "\""
          %Continuation{} = arg -> "\"" <> Continuation.to_string(arg) <> "\""
          true -> "\"" <> to_string(arg) <> "\""
        end
      end

    }
  end
end
