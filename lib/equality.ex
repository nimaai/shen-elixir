defmodule Klambda.Equality do
  alias Klambda.Cons

  def equal?(arg1, arg2) when is_number(arg1) and is_number(arg2) do
    arg1 == arg2
  end

  def equal?(arg1, arg2) when is_binary(arg1) and is_binary(arg2) do
    arg1 == arg2
  end

  def equal?(arg1, arg2) when is_atom(arg1) and is_atom(arg2) do
    arg1 == arg2
  end

  def equal?([_ | _] = cons1, [_ | _] = cons2) do
    cons1 == cons2
  end

  def equal?(arg1, arg2) when is_function(arg1) and is_function(arg2) do
    arg1 == arg2
  end

  def equal?(arg1, arg2) when is_function(arg1) and is_function(arg2) do
    arg1 == arg2
  end

  def equal?([:lambda, id1 | _], [:lambda, id2 | _]) do
    id1 == id2
  end

  def equal?(arg1, arg2) when is_pid(arg1) and is_pid(arg2) do
    arg1 == arg2
  end

  def equal?(_arg1, _arg2) do
    false
  end
end
