defmodule Klambda.Eval do
  alias Klambda.Lambda
  alias Klambda.Env
  import Klambda.Curry
  require IEx
  require Integer

  # TODO: check eval args in function calls !
  # TODO: raise error on arg type mismatch !

  ##################### FUNCTIONS AND BINDINGS ###################

  def eval([:defun, f, [], body]) do
    :ok = Env.define_function(f, fn -> eval(body) end)
    f
  end

  def eval([:defun, f, ps, body]) when is_atom(f) do
    v_vars = [:v1, :v2] |> Enum.map(&(Macro.var &1, __MODULE__))

    q = quote do
      fn(unquote_splicing(v_vars)) ->
        eval beta_reduce(
          unquote(Enum.zip(ps, v_vars)),
          var!(body)
        )
      end
    end

    {fn_obj, _} =
      Code.eval_quoted(q,
                       [body: body],
                       functions: [{__MODULE__, [{:beta_reduce, 2},
                                                 {:eval, 1}]}])

    :ok = Env.define_function(f, fn_obj)
    f
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

  def eval([f | args]) when is_atom(f) do
    fn_obj = Env.lookup_function(f)
    eval([fn_obj | args])
  end

  def eval([f | args]) when is_function(f) do
    {_, arity} = :erlang.fun_info(f, :arity)
    if arity == length(args) do
      apply(f, args)
    else
      partially_apply(curry(f), map_eval(args))
    end
  end

  def eval([[_ | _] = f | args]) do
    eval([eval(f) | map_eval(args)])
  end

  def partially_apply(f, args) do
    Enum.reduce(args, f, fn(arg, f) -> f.(arg) end)
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
