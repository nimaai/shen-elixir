defmodule Kl.Lambda do
  require IEx

  # param is not free
  def beta_reduce([:lambda, param, _] = lambda, param, _) do
    lambda
  end

  # param is free
  def beta_reduce([:lambda, param_x, body], param_y, val) do
    [:lambda, param_x, beta_reduce(body, param_y, val)]
  end

  def beta_reduce([fst | rest], param, val) do
    [beta_reduce(fst, param, val) | beta_reduce(rest, param, val)]
  end

  def beta_reduce(param, param, val) when is_atom(param) do
    val
  end

  def beta_reduce([], _, _) do
    []
  end

  def beta_reduce(val, _, _) do
    val
  end
end
