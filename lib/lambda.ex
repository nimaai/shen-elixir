defmodule Lisp.Lambda do
  alias Lisp.Reader.Eval
  alias Lisp.Bindings
  require IEx

  defstruct params: [], body: [], env: %{}

  def call(%Lisp.Lambda{params: params, body: body, env: env}, args) do
    {:ok, new_env} =
      params
      |> Enum.zip(args)
      |> Map.new
      |> Map.merge(if is_pid(env), do: Bindings.bindings(env), else: env)
      |> Bindings.start_link

    apply(&Eval.eval(&1, new_env), body)
  end

  def call(nil, _args) do
    raise "SyntaxError: undefined function call"
  end
end
