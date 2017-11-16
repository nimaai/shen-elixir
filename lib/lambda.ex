defmodule Klambda.Lambda do
  alias Klambda.Reader.Eval
  require IEx

  @enforce_keys :id
  defstruct id: nil, params: [], body: []

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

  def to_string(%Klambda.Lambda{id: id}) do
    "<lambda #{id}>"
  end

  def create(params, body) do
    %Klambda.Lambda{
      id: Base.encode16( :crypto.strong_rand_bytes(6) ),
      params: params,
      body: body
      }
  end
end
