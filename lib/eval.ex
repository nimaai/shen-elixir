defmodule Klambda.Eval do
  alias Klambda.Env
  require IEx
  require Integer

  @type expr :: kl_atom | fun_app

  @type kl_atom :: atom
                 | String.t
                 | number
                 | boolean
                 | pid
                 | function

  @type env :: map
  @type simple_error :: {:"simple-error", String.t}
  @type fun_app :: [operator | list(expr)]
  @type operator :: atom | fun_app

  # TODO: raise error on arg type mismatch !

  ##################### FUNCTIONS AND BINDINGS ###################

  @spec eval(expr, env) :: expr

  def eval([:defun, f, [], body], %{}) do
    :ok = Env.define_function(f, fn -> eval(body, %{}) end)
    f
  end

  def eval([:defun, f, ps, body], %{}) do
    :ok = Env.define_function(f, curry_defun(ps, body, %{}))
    f
  end

  def eval([:lambda, p, body], env) when is_atom(p) do
    fn(v) -> eval(body, Map.put(env, p, v)) end
  end

  def eval([:let, p, v, body], env) do
    eval(body, Map.put(env, p, v))
  end

  def eval([:freeze, expr], env) do
    fn -> eval(expr, env) end
  end

  # NOTE: possible shen override
  # def eval([:thaw, expr], env) do
  #   eval(expr, env).()
  # end

  ##################### CONDITIONALS #############################

  def eval([:if, condition, consequent, alternative], env) do
    if eval(condition, env) do
      eval(consequent, env)
    else
      eval(alternative, env)
    end
  end

  def eval([:cond, [condition, consequent] | rest], env) do
    if eval(condition, env) do
      eval(consequent, env)
    else
      eval([:cond | rest], env)
    end
  end

  def eval([:cond], _env), do: []

  def eval([:and, arg1, arg2], env) do
    eval(arg1, env) and eval(arg2, env)
  end

  def eval([:or, arg1, arg2], env) do
    eval(arg1, env) or eval(arg2, env)
  end

  ##################### ERROR HANDLING #####################################

  def eval([:"trap-error", body, handler], env) do
    evaled_body = eval_or_simple_error(body, env)
    evaled_handler = eval(handler, env)
    eval([[[:"trap-error"], evaled_body], evaled_handler], env)
  end

  def eval([:"trap-error", body], env) do
    evaled_body = eval_or_simple_error(body, env)
    eval([[:"trap-error"], evaled_body], env)
  end

  ##########################################################################

  def eval([[:lambda, _, _] = f, arg], env) do
    eval(f, env).(eval(arg, env))
  end

  def eval([f | args], env) when is_atom(f) do
    eval([Env.lookup_function(f) | args], env)
  end

  def eval([f | args], env) when is_function(f) do
    partially_apply(f, map_eval(args, env))
  end

  def eval([[_ | _] = f | args], env) do
    eval([eval(f, env) | map_eval(args, env)], env)
  end

  def eval(term, env) when is_atom(term) do
    env[term] || term
  end

  def eval(term, _env) do
    term
  end

  ##########################################################################

  @spec partially_apply(function, list(kl_atom)) :: kl_atom

  def partially_apply(f, args) do
    Enum.reduce(args, f, fn(arg, f) -> f.(arg) end)
  end

  @spec eval_or_simple_error(expr, env) :: kl_atom | simple_error

  def eval_or_simple_error(expr, env) do
    try do
      eval(expr, env)
    catch
      {:"simple-error", _message} = simple_error -> simple_error
    end
  end

  @spec map_eval(list(expr), env) :: list(kl_atom)

  def map_eval(args, env) do
    Enum.map(args, fn(arg) -> eval(arg, env) end)
  end

  @spec curry_defun(list(atom), expr, env) :: kl_atom | function

  def curry_defun([], body, env) do
    eval(body, env)
  end

  def curry_defun([p | r], body, env) do
    fn(v) -> curry_defun(r, body, Map.put(env, p, v)) end
  end
end
