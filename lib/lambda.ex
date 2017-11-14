defmodule Klambda.Lambda do
  alias Klambda.Reader.Eval
  require IEx

  defstruct params: [], body: []

  def call(%Klambda.Lambda{params: params, body: body}, evaled_args, env) do
    new_locals = Map.merge(env[:locals],
                           params |> Enum.zip(evaled_args) |> Map.new)

    new_env = Map.update!(env,
                          :locals,
                          fn _ -> new_locals end)

    apply(&Eval.eval(&1, new_env), body)
  end

  def call(nil, _args) do
    throw {:error, "SyntaxError: undefined function call"}
  end

  def to_string(%Klambda.Lambda{}) do
    "<lambda ...>"
  end
end
