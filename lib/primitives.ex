defmodule Klambda.Primitives do
  alias Klambda.Env
  alias Klambda.Eval
  alias Klambda.Equality
  alias Klambda.Print
  import Klambda.Curry
  require IEx

  def mapping do
    m = %{
      ##################### CONDITIONALS #############################

      and: &and/2,

      or: &or/2,

      if: fn(condition, consequent, alternative) ->
        if condition, do: consequent, else: alternative
      end,

      ##################### ERROR HANDLING ###########################

      "trap-error": fn(body, handler) ->
        if match?({:"simple-error", _}, body) do
          Eval.eval([handler, body])
        else
          body
        end
      end,

      "simple-error": fn(message) -> throw {:"simple-error", message} end,

      "error-to-string": fn({:"simple-error", message}) -> message end,

      ######################### SYMBOLS ##############################

      intern: &String.to_atom/1,

      set: fn(sym, val) ->
        :ok = Env.define_global(sym, val)
        val
      end,

      value: &Env.lookup_global/1,

      ######################### NUMERICS #############################

      number?: &is_number/1,

      +: &+/2,

      -: &-/2,

      *: &*/2,

      /: (&//2),

      >: &>/2,

      <: &</2,

      >=: &>=/2,

      <=: &<=/2,

      ######################### STRINGS ##############################

      "string?": &is_bitstring/1,

      pos: fn(arg, n) ->
        unit = String.at(arg, n)
        if is_nil(unit) do
          throw {:"simple-error", "String index is out bounds"}
        else
          unit
        end
      end,

      tlstr: fn(arg) ->
        if String.length(arg) == 0 do
          throw {:"simple-error", "Argument is empty string"}
        else
          {_, tlstr} = String.split_at(arg, 1)
          tlstr
        end
      end,

      cn: &<>/2,

      str: fn(arg) ->
        cond do
          is_bitstring(arg) -> "\"" <> arg <> "\""
          is_number(arg) -> to_string(arg)
          is_atom(arg) -> to_string(arg)
          is_function(arg) -> inspect(arg)
          is_pid(arg) -> inspect(arg)
          match?([:lambda | _], arg) -> Print.print(arg)
          match?({:vector, _, _}, arg) -> Print.print(arg)
          true -> throw {:"simple-error", "argument cannot be converted to string"}
        end
      end,

      "string->n": fn(arg) ->
        if String.length(arg) == 0 do
          throw {:"simple-error", "Argument is empty string"}
        else
          List.first(String.to_charlist(arg))
        end
      end,

      "n->string": fn(arg) ->
        if String.valid? <<arg>> do
          <<arg>>
        else
          throw {:"simple-error", "Not a valid codepoint"}
        end
      end,

      ############################ ARRAYS #####################################

      absvector: fn(size) ->
        # TODO: raise error if size negative or exceeds platform
        tuple = Tuple.duplicate(:nil, size)
        {:ok, pid} = Agent.start_link(fn -> tuple end)
          {:vector, size, pid}
      end,

      "address->": fn({:vector, _, pid} = vector, pos, val) ->
        Agent.update(
          pid,
          fn(tuple) -> put_elem(tuple, pos, val) end
        )
        vector
      end,

      "<-address": fn({:vector, size, pid}, pos) ->
        if (pos + 1) <= size do
          Agent.get(pid, fn(tuple) -> elem(tuple, pos) end)
        else
          throw {:"simple-error", "tuple index out of bounds"}
        end
      end,

      "absvector?": fn(arg) ->
        if match?({:vector, _, _}, arg) do
          is_pid(elem(arg, 1))
        else
          false
        end
      end,

      ############################ CONSES #####################################

      "cons?": fn(arg) -> match?({:cons, [_ | _]}, arg) end,

      cons: fn(head, tail) -> {:cons, [head | tail]} end,

      hd: fn({:cons, [head | _]}) -> head end,

      tl: fn({:cons, [_ | tail]}) -> tail end,

      ############################ STREAMS ####################################

      "write-byte": fn(num, stream) ->
        # TODO: raise error if stream closed or on in out mode
        :ok = IO.binwrite( stream, to_string(<<num>>) )
        num
      end,

      "read-byte": fn(stream) ->
        # TODO: raise error if stream closed or on in in mode
        char = IO.binread( stream, 1 )
        <<num, _>> = char <> <<0>>
        case num do
          :oef -> -1
          _ -> num
        end
      end,

      open: fn(path, mode) ->
        m = case mode do
          :in -> :read
          :out -> :write
          _ -> {:"simple-error", "invalid mode"}
        end
        {:ok, pid} = File.open( path, [m] )
        pid
      end,

      close: fn(stream) ->
        true = Process.exit( stream, :kill )
        []
      end,

      ############################ GENERAL ####################################

      "=": &Equality.equal?/2,

      "eval-kl": fn(kl_expr) -> kl_expr |> cons_to_list |> Eval.eval end,

      ######################### INFORMATIONAL #################################

      "get-time": fn(arg) ->
        now = DateTime.utc_now() |> DateTime.to_unix()
        case arg do
          :unix -> now
          :run -> now - Agent.get(:env, fn state -> state[:start_time] end)
          _ -> throw {:"simple-error", "invalid symbol for get-time"}
        end
      end,

      type: fn(arg, _sym) -> Eval.eval(arg) end
    }

    m
    |> Enum.map(fn({name, func}) -> {name, curry(func)} end)
    |> Enum.into(%{})
  end

  def cons_to_list({:cons, []}), do: []
  def cons_to_list({:cons, [fst | rest]}) do
    [cons_to_list(fst) | cons_to_list(rest)]
  end
  def cons_to_list(el), do: el
end
