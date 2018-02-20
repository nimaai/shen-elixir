defmodule Klambda.Lambda do
  require IEx

  def create(param, body) do
    [:lambda,
     Base.encode16(:crypto.strong_rand_bytes(6)),
     param,
     body]
  end

  def beta_reduce([:lambda, param, body], param, val) do
    beta_reduce_body(body, param, val)
  end

  # param is not free
  def beta_reduce_body([:lambda, param, _] = lambda, param, _) do
    lambda
  end

  # param is free
  def beta_reduce_body([:lambda, param_x, body], param_y, val) do
    [:lambda, param_x, beta_reduce_body(body, param_y, val)]
  end

  def beta_reduce_body([fst | rest], param, val) do
    [beta_reduce_body(fst, param, val) | beta_reduce_body(rest, param, val)]
  end

  def beta_reduce_body(param, param, val) when is_atom(param) do
    val
  end

  def beta_reduce_body([], _, _) do
    []
  end

  def beta_reduce_body(val, _, _) do
    val
  end
end
