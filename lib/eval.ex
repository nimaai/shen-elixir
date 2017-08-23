defmodule Lisp.Reader.Eval do
  alias Lisp.Bindings
  alias Lisp.Lambda
  alias Lisp.Env
  require IEx
  require Integer

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

  def eval([:if, condition, consequent, alternative], env) do
    if eval(condition, env) == true do
      eval(consequent, env)
    else
      eval(alternative, env)
    end
  end

  def eval([:cond, condition, consequent | rest], env) do
    if [condition, consequent | rest] |> length |> Integer.is_odd do
      throw {:error, "Unbalanced cond clauses"}
    end

    if eval(condition, env) == true do
      eval(consequent, env)
    else
      eval([:cond | rest], env)
    end
  end

  def eval([:cond, _condition], _env) do
    throw {:error, "Unbalanced cond clause"}
  end

  def eval([:cond], _env) do
    throw {:error, "No matching cond clause"}
  end

  def eval([f | args], env) do
    fun = case f do
      f when is_atom(f) -> Env.lookup_function(env, f)
      f = [:lambda | _] -> eval(f, env)
    end

    evaled_args = Enum.map(args, &eval(&1, env))
    eval_function_call(fun, evaled_args, env)
  end

  def eval(term, _env) when is_boolean(term) do
    term
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
