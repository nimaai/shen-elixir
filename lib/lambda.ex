defmodule Klambda.Lambda do
  alias Klambda.Reader.Eval
  require IEx

  @enforce_keys :id
  defstruct id: nil, param: nil, body: []

  def call(%Klambda.Lambda{param: param, body: body}, arg, env) do
    new_locals = Map.merge(env[:locals], %{param => arg})
    new_env = Map.update!(env, :locals, fn _ -> new_locals end)
    apply(&Eval.eval(&1, new_env), body)
  end

  def call(nil, _args) do
    throw {:error, "SyntaxError: undefined function call"}
  end

  def reduce1([:lambda, target, body], target, val) do
    reduce1(body, target, val)
  end

  def reduce1([:lambda, param, body], target, val) do
    [:lambda, param, reduce1(body, target, val)]
  end

  def reduce1(body, target, val) do
    i = Enum.find_index(body, &(&1 == target))
    List.replace_at(body, i, val)
  end

  def to_string(%Klambda.Lambda{id: id}) do
    "<lambda #{id}>"
  end

  def create(param, body) when is_atom(param) do
    %Klambda.Lambda{
      id: Base.encode16( :crypto.strong_rand_bytes(6) ),
      param: param,
      body: body
      }
  end
end
