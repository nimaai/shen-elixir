defmodule Klambda.Eval do
  alias Klambda.Env
  alias Klambda.Types, as: T
  alias Klambda.SimpleError
  require IEx
  require Integer

  @spec eval(T.expr, T.env) :: T.expr
  def eval([:defun, f, [], b], %{}) do
    :ok = Env.define_function(f, fn -> eval(b, %{}) end)
    f
  end

  def eval([:defun, f, ps, b], %{}) do
    :ok = Env.define_function(f, curry_defun(ps, b, %{}))
    f
  end

  def eval([:lambda, p, b], e) when is_atom(p) do
    fn(v) -> eval(b, Map.put(e, p, v)) end
  end

  def eval([:let, p, v, b], e) do
    eval(b, Map.put(e, p, v))
  end

  def eval([:freeze, x], e) do
    fn -> eval(x, e) end
  end

  # NOTE: possible shen override
  # def eval([:thaw, expr], e) do
  #   eval(expr, e).()
  # end

  def eval([:if, x, y, z], e) do
    if eval(x, e), do: eval(y, e), else: eval(z, e)
  end

  def eval([:cond, [x, y] | z], e) do
    if eval(x, e), do: eval(y, e), else: eval([:cond | z], e)
  end

  def eval([:cond], _e), do: []

  def eval([:and, x, y], e) do
    eval(x, e) and eval(y, e)
  end

  def eval([:or, x, y], e) do
    eval(x, e) or eval(y, e)
  end

  def eval([:"trap-error", x, f], e) do
    try do
      eval(x, e)
    rescue
      ex in SimpleError -> eval(f, e).(ex)
    end
  end

  def eval([[:lambda, _, _] = f, x], e) do
    eval(f, e).(eval(x, e))
  end

  def eval([f | xs], e) when is_atom(f) do
    eval([Env.lookup_function(f) | xs], e)
  end

  def eval([f | xs], e) when is_function(f) do
    p_apply(f, map_eval(xs, e))
  end

  def eval([[_ | _] = f | xs], e) do
    eval([eval(f, e) | map_eval(xs, e)], e)
  end

  def eval(x, e) when is_atom(x) do
    e[x] || x
  end

  def eval(x, _e) do
    x
  end

  @spec p_apply(fun, list(T.kl_atom)) :: T.kl_atom
  def p_apply(f, xs) do
    Enum.reduce(xs, f, fn(x, f) -> f.(x) end)
  end

  @spec map_eval(list(T.expr), T.env) :: list(T.kl_atom)
  def map_eval(xs, e) do
    Enum.map(xs, fn(x) -> eval(x, e) end)
  end

  @spec curry_defun(list(atom), T.expr, T.env) :: T.kl_atom | fun
  def curry_defun([], x, e) do
    eval(x, e)
  end
  def curry_defun([p | r], x, e) do
    fn(v) -> curry_defun(r, x, Map.put(e, p, v)) end
  end
end
