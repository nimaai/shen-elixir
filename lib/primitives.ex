defmodule KL.Primitives do
  alias KL.Env, as: E
  import KL.Eval, only: [eval: 2]
  alias KL.Equality
  alias KL.Print
  alias KL.Types, as: T
  import KL.Curry
  require IEx

  @spec kl_and(boolean, boolean) :: boolean
  def kl_and(x, y) when is_boolean(x) and is_boolean(y), do: x and y

  @spec kl_or(boolean, boolean) :: boolean
  def kl_or(x, y) when is_boolean(x) and is_boolean(y), do: x or y

  @spec kl_if(boolean, T.kl_atom, T.kl_atom) :: T.kl_atom
  def kl_if(x, y, z) when is_boolean(x), do: if x, do: y, else: z

  @spec trap_error(Exception.t | T.kl_atom, fun) :: T.kl_atom
  def trap_error(%KL.SimpleError{} = x, f), do: f.(x)
  def trap_error(x, _f), do: x

  @spec simple_error(String.t) :: Exception.t
  def simple_error(x) when is_binary(x), do: raise KL.SimpleError, message: x

  @spec error_to_string(Exception.t) :: String.t
  def error_to_string(x) do
    if match?(%KL.SimpleError{}, x) do
      x.message
    else
      Exception.format_banner(:error, x)
    end
  end

  @spec intern(String.t) :: atom
  def intern(x), do: String.to_atom(x)

  @spec set(atom, T.kl_atom) :: atom
  def set(x, y) do
    :ok = E.define_global(x, y)
    x
  end

  @spec value(atom) :: T.kl_atom
  def value(x), do: E.lookup_global(x)

  @spec number?(T.kl_atom) :: boolean
  def number?(x), do: is_number(x)

  @spec add(number, number) :: number
  def add(x, y), do: x + y

  @spec subtract(number, number) :: number
  def subtract(x, y), do: x - y

  @spec multiply(number, number) :: number
  def multiply(x, y), do: x * y

  @spec divide(number, number) :: number
  def divide(x, y), do: x / y

  @spec greater_than(number, number) :: number
  def greater_than(x, y), do: x > y

  @spec less_than(number, number) :: number
  def less_than(x, y), do: x < y

  @spec greater_or_equal_than(number, number) :: number
  def greater_or_equal_than(x, y), do: x >= y

  @spec less_or_equal_than(number, number) :: number
  def less_or_equal_than(x, y), do: x <= y

  @spec string?(T.kl_atom) :: boolean
  def string?(x), do: is_binary(x)

  @spec pos(String.t, number) :: String.t
  def pos(x, y) do
    z = String.at(x, y)
    if is_nil(z) do
      raise "string index is out of bounds"
    else
      z
    end
  end

  @spec tlstr(String.t) :: String.t
  def tlstr(x) when is_binary(x) do
    if String.length(x) == 0 do
      raise "argument is empty string"
    else
      {_, tlstr} = String.split_at(x, 1)
      tlstr
    end
  end

  @spec cn(String.t, String.t) :: String.t
  def cn(x, y) when is_binary(x) and is_binary(y), do: x <> y


  def mapping do
    m = %{
      and: &kl_and/2,
      or: &kl_or/2,
      if: &kl_if/3,
      "trap-error": &trap_error/2,
      "simple-error": &simple_error/1,
      "error-to-string": &error_to_string/1,
      intern: &intern/1,
      set: &set/2,
      value: &value/1,
      number?: &number?/1,
      +: &add/2,
      -: &subtract/2,
      *: &multiply/2,
      /: &divide/2,
      >: &greater_than/2,
      <: &less_than/2,
      >=: &greater_or_equal_than/2,
      <=: &less_or_equal_than/2,
      "string?": &string?/1,
      pos: &pos/2,
      tlstr: &tlstr/1,

      cn: &<>/2,
      str: fn(arg) ->
        cond do
          is_binary(arg) -> "\"" <> arg <> "\""
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
          :eof -> -1
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

      "eval-kl": fn(kl_expr) -> kl_expr |> cons_to_list |> eval(%{}) end,

      ######################### INFORMATIONAL #################################

      "get-time": fn(arg) ->
        now = DateTime.utc_now() |> DateTime.to_unix()
        case arg do
          :unix -> now
          :run -> now - Agent.get(:env, fn state -> state[:start_time] end)
          _ -> throw {:"simple-error", "invalid symbol for get-time"}
        end
      end,

      type: fn(arg, _sym) -> eval(arg, %{}) end
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
