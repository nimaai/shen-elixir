defmodule Klambda.Continuation do
  defstruct body: [], locals: %{}

  def to_string(%Klambda.Continuation{}) do
    "<cont ...>"
  end
end
