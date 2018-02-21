defmodule Klambda.Eval do
  alias Klambda.Lambda
  alias Klambda.Env
  import Klambda.Curry
  require IEx
  require Integer

  # TODO: check eval args in function calls !
  # TODO: raise error on arg type mismatch !

  ##################### FUNCTIONS AND BINDINGS ###################

  def eval([:defun, f, [], body], _env) do
    :ok = Env.define_function(f, fn -> eval(body) end)
    f
  end

  def eval([:defun, f, ps, body], env) do
    [p | rest] = Enum.reverse(ps)
    fn_obj =
      Enum.reduce(rest,
                  [:lambda, p, body],
                  fn(p, form) -> [:lambda, p, form] end)
      |> eval(env)
    :ok = Env.define_function(f, fn_obj)
    f
  end

  def eval([:freeze, expr]) do
    Lambda.create(nil, expr)
  end

  # NOTE: possible shen override
  # def eval([:thaw, expr]) do
  #   [:lambda, _id, nil, body] = eval(expr)
  #   eval(body)
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
    eval([[[:"trap-error"], evaled_body], evaled_handler])
  end

  def eval([:"trap-error", body], env) do
    evaled_body = eval_or_simple_error(body, env)
    eval([[:"trap-error"], evaled_body], env)
  end

  ###################### FUNCTION APPLICATION (PARTIAL) ####################

  # def eval([f | args]) when is_atom(f) do
  #   eval([Env.lookup_function(f) | args])
  # end

  # def eval([f | args]) when is_function(f) do
  #   partially_apply(f, map_eval(args))
  # end

  # def eval([[:lambda, _, _] = f, arg]) do
  #   eval([eval(f), eval(arg)])
  # end

  # def eval([[_ | _] = f | args]) do
  #   eval([eval(f) | map_eval(args)])
  # end

  ##########################################################################

  # def eval(term) do
  #   term
  # end

  ##########################################################################
  ##########################################################################
  ##########################################################################

  def eval([:let, p, v, body], env) do
    eval(body, Map.put(env, p, v))
  end

  def eval([:lambda, p, body], env) when is_atom(p) do
    fn(v) -> eval(body, Map.put(env, p, v)) end
  end

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

  def partially_apply(f, args) do
    Enum.reduce(args, f, fn(arg, f) -> f.(arg) end)
  end

  def eval_or_simple_error(expr, env) do
    try do
      eval(expr, env)
    catch
      {:"simple-error", _message} = simple_error -> simple_error
    end
  end

  def map_eval(args, env) do
    Enum.map(args, fn(arg) -> eval(arg, env) end)
  end

  # NOTE: why renaming this function breaks the macro???
  def beta_reduce(psvs, body) do
    [{p1, v1} | r] = Enum.reverse(psvs)
    Enum.reduce(r,
                Lambda.beta_reduce(body, p1, v1),
                fn({p, v}, form) -> Lambda.beta_reduce(form, p, v) end)
  end
end
