defmodule Klambda.Primitives do
  alias Klambda.Env
  alias Klambda.Eval
  alias Klambda.Vector
  alias Klambda.Cons
  alias Klambda.Equality
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
      end,

      ############################ CONSES #####################################

      "cons?": fn(arg) ->
        match?( %Cons{}, arg )
      end,

      cons: fn(head) -> fn(tail) ->
        %Cons{
          head: head,
          tail: if match?( [], tail ) do
            :end_of_cons
          else
            tail
          end
        }
      end end,

      hd: fn(arg) ->
        case arg do
          %Cons{head: head} -> head
          _ -> throw {:error, "Argument is not a cons"}
        end
      end,

      tl: fn(arg) ->
        case arg do
          %Cons{tail: tail} -> tail
          _ -> throw {:error, "Argument is not a cons"}
        end
      end,

      ############################ STREAMS ####################################

      "write-byte": fn(num) -> fn(stream) ->
        # TODO: raise error if stream closed or on in out mode
        :ok = IO.binwrite( stream, to_string(<<num>>) )
        num
      end end,

      "read-byte": fn(stream) ->
        # TODO: raise error if stream closed or on in in mode
        char = IO.binread( stream, 1 )
        <<num, _>> = char <> <<0>>
        case num do
          :oef -> -1
          _ -> num
        end
      end,

      open: fn(path) -> fn(mode) ->
        m = case mode do
          :in -> :read
          :out -> :write
          _ -> {:"simple-error", "invalid mode"}
        end
        {:ok, pid} = File.open( path, [m] )
        pid
      end end,

      close: fn(stream) ->
        true = Process.exit( stream, :kill )
        []
      end,

      ############################ GENERAL ####################################

      "=": fn(arg1) -> fn(arg2) ->
        Equality.equal?(arg1, arg2)
      end end,

      "eval-kl": fn(kl_expr) ->
        Eval.eval kl_expr
      end,

      ######################### INFORMATIONAL #################################

      "get-time": fn(arg) ->
        now = DateTime.utc_now() |> DateTime.to_unix()
        case arg do
          :unix -> now
          :run -> now - Agent.get(:env, fn state -> state[:start_time] end)
          _ -> throw {:error, "invalid symbol for get-time"}
        end
      end,

      type: fn(arg) -> fn(_sym) ->
        Eval.eval(arg)
      end end

    }
  end
end
