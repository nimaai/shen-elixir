defmodule Lisp.Reader.Eval do
  alias Lisp.Types
  alias Lisp.Bindings
  alias Lisp.Lambda
  alias Lisp.Env
  require IEx

  # @spec eval(Types.valid_term, pid) :: Types.valid_term | no_return
  def eval([:defun, f, params | body], env) do
    Bindings.define(env[:global_functions],
                    f,
                    %Lambda{params: params, body: body, env: env})
  end

  def eval([:lambda, params | body], env) do
    %Lambda{params: params, body: body, env: env}
  end

  def eval([:freeze | body], env) do
    %Lambda{params: [], body: body, env: env}
  end

  def eval([:if, condition, then_form, else_form], env) do
    if eval(condition, env) == true do
      eval(then_form, env)
    else
      eval(else_form, env)
    end
  end

  def eval([f | args], env) when is_atom(f) do
    fun = Env.lookup_function(env, f)
    apply(fun, Enum.map(args, fn arg -> eval(arg, env) end))
  end

  # def eval([f | args], env) do
  #   partially_evaluated = Enum.map(args, fn
  #   # If the argument is a list, `eval` it as well.
  #     ([_x | _xs] = arg) ->
  #       eval(arg, env)
  #   # If the argument is a symbol, look it up in the env.
  #     arg when is_atom(arg) ->
  #       Bindings.lookup(env, arg)
  #   # Otherwise, just return it.
  #     arg ->
  #       arg
  #   end)

  #   case Env.lookup_function(env, f) do
  #     fun when is_function(fun) ->
  #       fun.(partially_evaluated)
  #     lambda = %Lambda{} ->
  #       Lambda.call(lambda, partially_evaluated)
  #     _ ->
  #       Lambda.call(eval(f, env), partially_evaluated)
  #   end
  # end

  def eval(term, env) when is_atom(term) do
    env[:locals][term] or term
  end

  # def eval(term, _env) do
  #   term
  # end
end
