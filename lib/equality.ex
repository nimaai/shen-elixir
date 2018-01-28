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

  def equal?(%Cons{head: head1, tail: tail1}, %Cons{head: head2, tail: tail2}) do
    equal?(head1, head2) && equal?(tail1, tail2)
  end

  def equal?(arg1, arg2) when is_function(arg1) and is_function(arg2) do
    arg1 == arg2
  end

  def equal?(arg1, arg2) when is_function(arg1) and is_function(arg2) do
    arg1 == arg2
  end

  # FIXME: lambda is simple list now
  # def equal?(%Lambda{id: id1}, %Lambda{id: id2}) do
  #   id1 == id2
  # end

  def equal?(arg1, arg2) when is_pid(arg1) and is_pid(arg2) do
    arg1 == arg2
  end

  def equal?(_arg1, _arg2) do
    false
  end
end
