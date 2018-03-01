defmodule KL.Equality do
  alias KL.Cons

  @spec equal?(T.kl_term, T.kl_term) :: boolean
  def equal?(x, y) when is_list(x) and is_list(y), do: x == y
  def equal?(x, y) when is_binary(x) and is_binary(y), do: x == y
  def equal?(x, y) when is_number(x) and is_number(y), do: x == y

  def equal?(x, y) when is_atom(x) and is_atom(y) do
    x == y
  end

  def equal?({:cons, list1}, {:cons, list2}) do
    list1 == list2
  end

  def equal?([], []) do
    true
  end

  def equal?(x, y) when is_function(x) and is_function(y) do
    x == y
  end

  def equal?(x, y) when is_function(x) and is_function(y) do
    x == y
  end

  def equal?([:lambda, id1 | _], [:lambda, id2 | _]) do
    id1 == id2
  end

  def equal?(x, y) when is_pid(x) and is_pid(y) do
    x == y
  end

  def equal?(_x, _y) do
    false
  end
end
