defmodule Klambda.Primitives do
  alias Klambda.Env
  alias Klambda.Eval
  alias Klambda.Equality
  alias Klambda.Print
  require IEx

  def mapping do
    %{
      ##################### CONDITIONALS #############################

      and: {2,
        fn(x, y) -> x and y end
      },

      or: {2,
        fn(x, y) -> x or y end
      },

      if: {3,
        fn(condition, consequent, alternative) ->
          if condition, do: consequent, else: alternative
        end
      },

      ##################### ERROR HANDLING ###########################

      "trap-error": {2,
        fn(body, handler) ->
          if match?({:"simple-error", _}, body) do
            Eval.eval([handler, body])
          else
            body
          end
        end
      },

      "simple-error": {1,
        fn(message) -> throw {:"simple-error", message} end
      },

      "error-to-string": {1,
        fn({:"simple-error", message}) -> message end
      },

      ######################### SYMBOLS ##############################

      intern: {1,
        fn(name) -> String.to_atom(name) end
      },

      set: {2,
        fn(sym, val) ->
          :ok = Env.define_global(sym, val)
          val
        end
      },

      value: {2,
        fn(sym) -> Env.lookup_global(sym) end
      },

      ######################### NUMERICS #############################

      number?: {1, &is_number/1},

      +: {2, &+/2},

      -: {2, &-/2},

      *: {2, &*/2},

      /: {2, &//2},

      >: {2, &>/2},

      <: {2, &</2},

      >=: {2, &>=/2},

      <=: {2, &<=/2},

      ######################### STRINGS ##############################

      "string?": {1, &is_bitstring/1},

      pos: {2,
        fn(arg, n) ->
          unit = String.at(arg, n)
          if is_nil(unit) do
            throw {:"simple-error", "String index is out bounds"}
          else
            unit
          end
        end
      },

      tlstr: {1,
        fn(arg) ->
          if String.length(arg) == 0 do
            throw {:"simple-error", "Argument is empty string"}
          else
            {_, tlstr} = String.split_at(arg, 1)
            tlstr
          end
        end
      },

      cn: {2, &<>/2},

      str: {1,
        fn(arg) ->
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
        end
      },

      "string->n": {1,
        fn(arg) ->
          if String.length(arg) == 0 do
            throw {:"simple-error", "Argument is empty string"}
          else
            List.first(String.to_charlist(arg))
          end
        end
      },

      "n->string": {1,
        fn(arg) ->
          if String.valid? <<arg>> do
            <<arg>>
          else
            throw {:"simple-error", "Not a valid codepoint"}
          end
        end
      },

      ############################ ARRAYS #####################################

      absvector: {1,
        fn(size) ->
          # TODO: raise error if size negative or exceeds platform
          tuple = Tuple.duplicate(:nil, size)
          {:ok, pid} = Agent.start_link(fn -> tuple end)
            {:vector, size, pid}
        end
      },

      "address->": {3,
        fn({:vector, _, pid} = vector, pos, val) ->
          Agent.update(
            pid,
            fn(tuple) -> put_elem(tuple, pos, val) end
          )
          vector
        end
      },

      "<-address": {2,
        fn({:vector, size, pid}, pos) ->
          if (pos + 1) <= size do
            Agent.get(pid, fn(tuple) -> elem(tuple, pos) end)
          else
            throw {:"simple-error", "tuple index out of bounds"}
          end
        end
      },

      "absvector?": {1,
        fn(arg) ->
          if match?({:vector, _, _}, arg) do
            is_pid(elem(arg, 1))
          else
            false
          end
        end
      },

      ############################ CONSES #####################################

      "cons?": {1,
        fn(arg) -> match?({:cons, [_ | _]}, arg) end
      },

      cons: {2,
        fn(head, tail) -> {:cons, [head | tail]} end
      },

      hd: {1,
        fn({:cons, [head | _]}) -> head end
      },

      tl: {1,
        fn({:cons, [_ | tail]}) -> tail end
      },

      ############################ STREAMS ####################################

      "write-byte": {2,
        fn(num, stream) ->
          # TODO: raise error if stream closed or on in out mode
          :ok = IO.binwrite( stream, to_string(<<num>>) )
          num
        end
      },

      "read-byte": {1,
        fn(stream) ->
          # TODO: raise error if stream closed or on in in mode
          char = IO.binread( stream, 1 )
          <<num, _>> = char <> <<0>>
          case num do
            :oef -> -1
            _ -> num
          end
        end
      },

      open: {2,
        fn(path, mode) ->
          m = case mode do
            :in -> :read
            :out -> :write
            _ -> {:"simple-error", "invalid mode"}
          end
          {:ok, pid} = File.open( path, [m] )
          pid
        end
      },

      close: {1,
        fn(stream) ->
          true = Process.exit( stream, :kill )
          []
        end
      },

      ############################ GENERAL ####################################

      "=": {2, &Equality.equal?/2},

      "eval-kl": {1,
        fn(kl_expr) ->
          kl_expr |> cons_to_list |> Eval.eval
        end
      },

      ######################### INFORMATIONAL #################################

      "get-time": {1,
        fn(arg) ->
          now = DateTime.utc_now() |> DateTime.to_unix()
          case arg do
            :unix -> now
            :run -> now - Agent.get(:env, fn state -> state[:start_time] end)
            _ -> throw {:"simple-error", "invalid symbol for get-time"}
          end
        end
      },

      type: {2,
        fn(arg, _sym) -> Eval.eval(arg) end
      }
    }
  end

  def cons_to_list({:cons, []}), do: []
  def cons_to_list({:cons, [fst | rest]}) do
    [cons_to_list(fst) | cons_to_list(rest)]
  end
  def cons_to_list(el), do: el
end
