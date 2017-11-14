defmodule Klambda.Cont do
  defstruct body: [], locals: %{}

  def to_string(%Klambda.Cont{}) do
    # "<Cont | Body: #{lispy_print(body)}> | Locals: #{Enum.map(locals, &lispy_print/1)}>"
    "<cont ...>"
  end
end
