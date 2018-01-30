defmodule Klambda.Lambda do
  def create(param, body) do
    [:lambda,
     Base.encode16(:crypto.strong_rand_bytes(6)),
     param,
     body]
  end

  def beta_reduce([:lambda, _, param, body], val) do
    subst(body, param, val)
  end

  defp subst([fst | rest], param, val) do
    [subst(fst, param, val) | subst(rest, param, val)]
  end

  defp subst(param, param, val) when is_atom(param) do
    val
  end

  defp subst([], _, _) do
    []
  end

  defp subst(param, _, _) do
    param
  end
end
