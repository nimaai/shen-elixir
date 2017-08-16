defmodule Lisp.Lambda do
  alias Lisp.Reader.Eval
  alias Lisp.Bindings
  require IEx

  defstruct params: [], body: [], env: %{}

  def call(%Lisp.Lambda{params: params, body: body, env: env}, args) do
    new_locals =
      params
      |> Enum.zip(args)
      |> Map.new
      |> Map.merge(env[:locals])

    new_env = %{
      locals: new_locals,
      globals: env[:globals],
      functions: env[:functions]
    }

    apply(&Eval.eval(&1, new_env), body)
  end

  def call(nil, _args) do
    raise "SyntaxError: undefined function call"
  end
end
