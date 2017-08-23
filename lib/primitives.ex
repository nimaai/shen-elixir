defmodule Lisp.Primitives do
  def mapping do
    %{
      +: &+/2,
      -: &-/2,
      *: &*/2,
      /: &(&1 / &2),
      number?: &is_number/1,
      >: &>/2,
      <: &</2,
      >=: &>=/2,
      <=: &<=/2
      # ^: &pow/1,
      # =: &equal/1,
      # "/=": &not_equal/1,
      # begin: &begin/1,
      # display: &display/1,
      # newline: &newline/1,
      # displayln: &displayln/1,
      # pi: 3.14159265359,
      # list: &list/1,
      # tuple: &tuple/1,
      # cons: &cons/1,
      # head: &head/1,
      # tail: &tail/1,
    }
  end
end
