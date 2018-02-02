defmodule Klambda.Cons do
  alias Klambda.Print

  @enforce_keys [:head]
  defstruct [:head, :tail]

  def to_string(%Klambda.Cons{ head: head, tail: tail }, open, close) do
    case tail do
      :end_of_cons ->
        "#{open}#{Print.print(head)}#{close}"
      %Klambda.Cons{} ->
        "#{open}#{Print.print(head)} #{to_string(tail, "", "")}#{close}"
      _ ->
        "#{open}#{Print.print(head)} | #{Print.print(tail)}#{close}"
    end
  end

  def to_list(%Klambda.Cons{ head: head, tail: tail }) do
    head2 = if match?(%Klambda.Cons{}, head) do
      to_list(head)
    else
      head
    end

    case tail do
      %Klambda.Cons{} ->
        [ head2 | to_list(tail) ]
      :end_of_cons ->
        [ head2 ]
      _ -> throw {:error, "cdr of cons is not a cons or nil"}
    end
  end
end
