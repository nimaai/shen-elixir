defmodule Lisp.Lambda do
  alias Lisp.Reader.Eval
  alias Lisp.Bindings
  require IEx

  defstruct params: [], body: [], locals: %{}

  def call(%Lisp.Lambda{params: params, body: body, locals: locals}, args, env) do
    new_locals =
      params
      |> Enum.zip(args)
      |> Map.new
      |> Map.merge(locals)

    {_, new_env} = Map.get_and_update(env,
                                      :locals,
                                      fn locals -> {locals, new_locals} end)

    apply(&Eval.eval(&1, new_env), body)
  end

  def call(nil, _args) do
    raise "SyntaxError: undefined function call"
  end
end
