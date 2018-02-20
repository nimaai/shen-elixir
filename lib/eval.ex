defmodule Klambda.Eval do
  alias Klambda.Lambda
  alias Klambda.Env
  import Klambda.Curry
  require IEx
  require Integer

  # TODO: check eval args in function calls !
  # TODO: raise error on arg type mismatch !

  ##################### FUNCTIONS AND BINDINGS ###################

  def eval([:defun, fn_name, params, body]) when is_atom(fn_name) do
    bbody =
      if match?([], params) do
        Lambda.create(nil, body)
      else
        [fst | rest] = Enum.reverse(params)
        Enum.reduce(
          rest,
          Lambda.create(fst, body),
          fn(param, lambda_acc) ->
            Lambda.create(param, lambda_acc)
          end
        )
      end
    :ok = Env.define_function(fn_name, bbody)
    fn_name
  end

  def eval([:lambda, param, body]) do
    if is_atom(param) do
      Lambda.create(param, body)
    else
      throw {:error, "Required argument is not a symbol"}
    end
  end

  def eval([:lambda, _id, _, _] = lambda) do
    lambda
  end

  def eval([:let, sym, val, body]) do
    eval [Lambda.create(sym, body), eval(val)]
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

  def eval([:if, condition, consequent, alternative]) do
    if eval(condition) do
      eval(consequent)
    else
      eval(alternative)
    end
  end

  def eval([:cond, [condition, consequent] | rest]) do
    if eval(condition) do
      eval(consequent)
    else
      eval([:cond | rest])
    end
  end

  def eval([:cond]), do: []

  def eval([:and, arg1, arg2]) do
    eval(arg1) and eval(arg2)
  end

  def eval([:or, arg1, arg2]) do
    eval(arg1) or eval(arg2)
  end

  ##################### ERROR HANDLING #####################################

  def eval([:"trap-error", body, handler]) do
    evaled_body = eval_or_simple_error(body)
    evaled_handler = eval(handler)
    eval([[[:"trap-error"], evaled_body], evaled_handler])
  end

  def eval([:"trap-error", body]) do
    evaled_body = eval_or_simple_error(body)
    eval([[:"trap-error"], evaled_body])
  end

  ###################### FUNCTION APPLICATION (PARTIAL) ####################

  def eval([f]) when is_function(f) do
    {_, arity} = :erlang.fun_info(f, :arity)
    f.()
  end

  def eval([f | args]) when is_atom(f) do
    Env.lookup_function(f) |> partially_apply(map_eval(args))
  end

  def eval([f | args]) when is_function(f) do
    partially_apply(f, map_eval(args))
  end

  def eval([[_ | _] = f | args]) do
    eval([eval(f) | map_eval(args)])
  end

  def partially_apply(f, args) do
    Enum.reduce(args, f, fn(arg, new_f) -> new_f.(arg) end)
  end

  ##########################################################################

  def eval(term) do
    term
  end

  ##########################################################################

  defp eval_or_simple_error(expr) do
    try do
      eval(expr)
    catch
      {:"simple-error", _message} = simple_error -> simple_error
    end
  end

  defp map_eval(args), do: Enum.map(args, &eval/1)

  def beta_reduce(psvs, body) do
    [{p1, v1} | r] = Enum.reverse(psvs)
    Enum.reduce(r,
                beta_reduce_once(body, p1, v1),
                fn({p, v}, form) -> beta_reduce_once(form, p, v) end)
  end

  def beta_reduce_once(body, p, v) do
    Lambda.beta_reduce([:lambda, p, body], p, v)
  end
end
