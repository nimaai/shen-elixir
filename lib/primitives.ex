defmodule KL.Primitives do
  alias KL.Equality
  alias KL.Env, as: E
  alias KL.Types, as: T
  alias KL.Eval
  import KL.Curry
  require IEx

  @spec kl_and(boolean, boolean) :: boolean
  def kl_and(x, y) when is_boolean(x) and is_boolean(y), do: x and y

  @spec kl_or(boolean, boolean) :: boolean
  def kl_or(x, y) when is_boolean(x) and is_boolean(y), do: x or y

  @spec kl_if(boolean, T.kl_term, T.kl_term) :: T.kl_term
  def kl_if(x, y, z) when is_boolean(x), do: if x, do: y, else: z

  @spec trap_error(Exception.t | T.kl_term, fun) :: T.kl_term
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

  @spec set(atom, T.kl_term) :: atom
  def set(x, y) do
    :ok = E.set_var(x, y)
    x
  end

  @spec value(atom) :: T.kl_term
  def value(x), do: E.get_var(x)

  @spec number?(T.kl_term) :: boolean
  def number?(x), do: is_number(x)

  @spec add(number, number) :: number
  def add(x, y), do: x + y

  @spec subtract(number, number) :: number
  def subtract(x, y), do: x - y

  @spec multiply(number, number) :: number
  def multiply(x, y), do: x * y

  @spec divide(number, number) :: number
  def divide(x, y), do: x / y

  @spec greater_than(number, number) :: boolean
  def greater_than(x, y), do: x > y

  @spec less_than(number, number) :: boolean
  def less_than(x, y), do: x < y

  @spec greater_or_equal_than(number, number) :: boolean
  def greater_or_equal_than(x, y), do: x >= y

  @spec less_or_equal_than(number, number) :: boolean
  def less_or_equal_than(x, y), do: x <= y

  @spec string?(T.kl_term) :: boolean
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

  @spec str(T.kl_term) :: String.t
  def str(x) do
    cond do
      match?([], x) -> raise "[] is not an atom in Shen; str cannot convert it to a string."
      is_atom(x) -> to_string(x)
      is_number(x) -> to_string(x)
      is_binary(x) -> ~s("#{x}")
      is_pid(x) -> inspect(x)
      is_function(x) -> inspect(x)
      true -> raise "#{inspect(x)} is not an atom, stream or closure; str cannot convert it to a string."
    end
  end

  @spec string_to_n(String.t) :: integer
  def string_to_n(x), do: List.first String.to_charlist(x)

  @spec n_to_string(integer) :: String.t
  def n_to_string(x), do: <<x>>

  @spec absvector(integer) :: {:vector, pid}
  def absvector(x) do
    {:ok, p} = Agent.start_link(fn -> :array.new(x) end)
    {:vector, p}
  end

  @spec put_to_address({:vector, pid}, integer, T.kl_term) :: {:vector, pid}
  def put_to_address({:vector, p}, y, z) do
    Agent.update(p, fn(a) -> :array.set(y, z, a) end)
    {:vector, p}
  end

  @spec get_from_address({:vector, pid}, integer) :: T.kl_term
  def get_from_address({:vector, p}, y) do
    Agent.get(p, fn(a) -> :array.get(a, y) end)
  end

  @spec absvector?(T.kl_term) :: boolean
  def absvector?({:vector, p}) when is_pid(p), do: true
  def absvector?(_), do: false

  @spec cons?(list(T.kl_term)) :: boolean
  def cons?(x), do: is_list(x)

  @spec cons(T.kl_term, T.kl_term) :: list(T.kl_term)
  def cons(x, y), do: [x | y]

  @spec kl_hd(list(T.kl_term)) :: T.kl_term
  def kl_hd(x), do: hd(x)

  @spec kl_tl(list(T.kl_term)) :: T.kl_term
  def kl_tl(x), do: tl(x)

  @spec write_byte({:stream, pid}, integer) :: integer
  def write_byte({:stream, s}, b) do
    IEx.pry
    :ok = IO.binwrite(s, <<b>>)
    b
  end

  @spec read_byte({:stream, pid}) :: integer
  def read_byte({:stream, s}) do
    c = IO.binread(s, 1)
    if c == :eof do
      -1
    else
      <<n, _>> = c <> <<0>>
      n
    end
  end

  @spec open(String.t, atom) :: {:stream, File.io_device}
  def open(x, y) do
    m = case y do
      :in -> :write
      :out -> :read
      _ -> raise "invalid direction"
    end
    {:ok, p} = File.open(x, [m])
    {:stream, p}
  end

  @spec close({:stream, pid}) :: nil
  def close({:stream, x}) do
    :ok = File.close(x)
    nil
  end

  @spec equal?(T.kl_term, T.kl_term) :: boolean
  def equal?(x, y), do: Equality.equal?(x, y)

  @spec eval_kl(list) :: T.kl_term
  def eval_kl(x), do: Eval.eval(x, %{})

  @spec get_time(T.kl_term) :: integer
  def get_time(x) do
    now = DateTime.utc_now() |> DateTime.to_unix()
    case x do
      :unix -> now
      :run -> now - Agent.get(:env, fn state -> state[:start_time] end)
      _ -> raise "get-time does not understand the parameter #{inspect(x)}"
    end
  end

  @spec type(T.kl_term, atom) :: T.kl_term
  def type(x, _y), do: x

  def mapping do
    %{
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
      cn: &cn/2,
      str: &str/1,
      "string->n": &string_to_n/1,
      "n->string": &n_to_string/1,
      absvector: &absvector/1,
      "address->": &put_to_address/3,
      "<-address": &get_from_address/2,
      "absvector?": &absvector?/1,
      "cons?": &cons?/1,
      cons: &cons/2,
      "hd": &kl_hd/1,
      "tl": &kl_tl/1,
      "write-byte": &write_byte/2,
      "read-byte": &read_byte/1,
      open: &open/2,
      close: &close/1,
      "=": &equal?/2,
      "eval-kl": &eval_kl/1,
      "get-time": &get_time/1,
      type: &type/2
    }
    |> Enum.map(fn({n, f}) -> {n, curry(f)} end)
    |> Enum.into(%{})
  end
end
