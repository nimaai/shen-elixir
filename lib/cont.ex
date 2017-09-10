defmodule Lisp.Cont do
  defstruct body: [], locals: %{}

  def to_string(%Lisp.Cont{}) do
    # "<Cont | Body: #{lispy_print(body)}> | Locals: #{Enum.map(locals, &lispy_print/1)}>"
    "<cont ...>"
  end
end
