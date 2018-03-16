defmodule Kl.Code do
  alias Kl.Env
  alias Kl.Eval
  require IEx

  def compile_function(xs, [_ | _] = b) do
    vars = Enum.map(xs, fn(x) -> Macro.var(x, nil) end)
    q = quote do
      fn(unquote_splicing(vars)) -> unquote(quote_body(b, xs)) end
    end
    {fo, _} = Code.eval_quoted(q)
    fo
  end

  def compile_function(ps, x) do
    vars = Enum.map(ps, fn(p) -> Macro.var(p, nil) end)
    q = quote do
      fn(unquote_splicing(vars)) -> unquote(quote_arg(x, ps)) end
    end
    {fo, _} = Code.eval_quoted(q)
    fo
  end

  def quote_body([f | gs] = b, xs) do
    if f == :cond do
      quote do: Eval.eval(unquote(b), %{})
    else
      quote do
        apply(
          Env.get_fn(unquote(f)),
          unquote(quote_args(gs, xs))
        )
      end
    end
  end

  def quote_args(as, xs) do
    Enum.map(as, fn(a) -> quote_arg(a, xs) end)
  end

  def quote_arg([f | gs], xs) do
    fq = if Enum.member?(xs, f) do
      Macro.var(f, nil)
    else
      quote do: E.get_fn(unquote(f))
    end
    quote do: apply(unquote(fq), unquote(quote_args(gs, xs)))
  end

  def quote_arg(a, xs) when is_atom(a) do
    if Enum.member?(xs, a) do
      Macro.var(a, nil)
    else
      a
    end
  end

  def quote_arg(a, _), do: a
end
