defmodule Klambda.Primitives do
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
      <=: &<=/2,
      and: &and/2,
      or: &or/2,
    }
  end

  def arities do
    %{
      +: 2
    }
  end
end
