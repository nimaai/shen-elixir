defmodule Lisp.Cons do
  alias Lisp.Reader

  @enforce_keys [:head]
  defstruct [:head, :tail]

  def to_string(%Lisp.Cons{ head: head, tail: tail }, open, close) do
    case tail do
      :end_of_cons ->
        "#{open}#{Reader.lispy_print(head)}#{close}"
      %Lisp.Cons{} ->
        "#{open}#{Reader.lispy_print(head)} #{to_string(tail, "", "")}#{close}"
      _ ->
        "#{open}#{Reader.lispy_print(head)} | #{Reader.lispy_print(tail)}#{close}"
    end
  end
end
