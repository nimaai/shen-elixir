defmodule Klambda.Primitives do
  alias Klambda.Env
  alias Klambda.Reader.Eval
  alias Klambda.Vector
  require IEx

  def mapping do
    %{
      ##################### CONDITIONALS #############################

      and: fn(x) -> fn(y) -> x and y end end,

      or: fn(x) -> fn(y) -> x or y end end,

      if: fn(condition) -> fn(consequent) -> fn(alternative) ->
        if condition, do: consequent, else: alternative
      end end end,

      ##################### ERROR HANDLING ###########################

      "trap-error": fn(body) -> fn(handler) ->
        try do
          body
        catch
          {:"simple-error", _message} -> Eval.eval([handler, body])
        end
      end end,

      "simple-error": fn(message) -> throw {:"simple-error", message} end,

      "error-to-string": fn({:"simple-error", message}) -> message end,

      ######################### SYMBOLS ##############################

      intern: fn(name) -> String.to_atom(name) end,

      set: fn(sym) -> fn(val) ->
        :ok = Env.define_global(sym, val)
        val
      end end,

      value: fn(sym) -> Env.lookup_global(sym) end,

      ######################### NUMERICS #############################

      number?: &is_number/1,

      +: fn(x) -> fn(y) -> x + y end end,

      -: fn(x) -> fn(y) -> x - y end end,

      *: fn(x) -> fn(y) -> x * y end end,

      /: fn(x) -> fn(y) -> x / y end end,

      >: fn(x) -> fn(y) -> x > y end end,

      <: fn(x) -> fn(y) -> x < y end end,

      >=: fn(x) -> fn(y) -> x >= y end end,

      <=: fn(x) -> fn(y) -> x <= y end end,

      ######################### STRINGS ##############################

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
          match?([:lambda | _], arg) -> "<lambda>"
          match?([_ | _], arg) -> "<continuation>"
          true -> to_string(arg)
        end
      end,

      "string->n": fn(arg) ->
        if String.length(arg) == 0 do
          throw {:error, "Argument is empty string"}
        else
          List.first(String.to_charlist(arg))
        end
      end,

      "n->string": fn(arg) ->
        if String.valid? <<arg>> do
           <<arg>>
        else
          throw {:error, "Not a valid codepoint"}
        end
      end,

      ############################ ARRAYS #####################################

      absvector: fn(arg) ->
        Vector.new(arg)
      end,

      "address->": fn(vec) -> fn(pos) -> fn(val) ->
        Vector.set(vec, pos, val)
      end end end,

      "<-address": fn(vec) -> fn(pos) ->
        Vector.get(vec, pos)
      end end,

      "absvector?": fn(arg) ->
        match?({:array, _}, arg)
      end

    }
  end
end
