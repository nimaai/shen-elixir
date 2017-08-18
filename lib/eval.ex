defmodule Lisp.Reader.Eval do
  alias Lisp.Bindings
  alias Lisp.Lambda
  alias Lisp.Env
  require IEx

  # @spec eval(Types.valid_term, pid) :: Types.valid_term | no_return
  def eval([:defun, f, params | body], env) do
    Bindings.define(env[:functions],
                    f,
                    %Lambda{params: params, body: body})
  end

  def eval([:lambda, param | body], env) do
    if is_atom(param) do
      %Lambda{params: [param], body: body, locals: env[:locals]}
    else
      throw {:error, "Required argument is not a symbol"}
    end
  end

  def eval([:let, sym, value | body], env) do
    Lambda.call(%Lambda{params: [sym], body: body}, [value], env)
  end

  def eval([:freeze | body], env) do
    %Lambda{params: [], body: body, locals: env[:locals]}
  end

  def eval([:if, condition, then_form, else_form], env) do
    if eval(condition, env) == true do
      eval(then_form, env)
    else
      eval(else_form, env)
    end
  end

  def eval([f | args], env) do
    fun = case f do
      f when is_atom(f) -> Env.lookup_function(env, f)
      f = [:lambda | _] -> eval(f, env)
    end

    evaled_args = Enum.map(args, &eval(&1, env))
    eval_function_call(fun, evaled_args, env)
  end

  def eval(term, env) when is_atom(term) do
    val = env[:locals][term]
    unless is_nil(val) do
      val
    else
      throw {:error, "Unbound variable #{term}"}
    end
  end

  def eval(term, _env) do
    term
  end

  defp eval_function_call(%Lambda{} = f, args, env) do
    Lambda.call(f, args, env)
  end

  defp eval_function_call(f, args, _env) when is_function(f) do
    apply(f, args)
  end
end
