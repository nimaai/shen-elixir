defmodule Klambda.Lambda do
  alias Klambda.Reader.Eval
  require IEx

  @enforce_keys :id
  defstruct id: nil, param: nil, body: []

  def call(%Klambda.Lambda{param: param, body: body}, arg, env) do
    new_locals = Map.merge(env[:locals], %{param => arg})
    new_env = Map.update!(env, :locals, fn _ -> new_locals end)
    Eval.eval(body, new_env)
  end

  def call(nil, _args) do
    throw {:error, "SyntaxError: undefined function call"}
  end

  def beta_reduce([:lambda, param, body], val) do
    subst(body, param, val)
  end

  defp subst([fst | rest], param, val) do
    [subst(fst, param, val) | subst(rest, param, val)]
  end

  defp subst(param, param, val) when is_atom(param) do
    val
  end

  defp subst(param, _, _) do
    param
  end

  defp subst([], _, _) do
    []
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
