defmodule Klambda.Eval do
  alias Klambda.Lambda
  alias Klambda.Env
  alias Klambda.Primitives
  require IEx
  require Integer

  # TODO: check eval args in function calls !
  # TODO: raise error on arg type mismatch !

  ##################### FUNCTIONS AND BINDINGS ###################

  def eval([:defun, fn_name, params, body]) when is_atom(fn_name) do
    bbody = if [] = params do
      Lambda.create(nil, body)
    else
      [fst | rest] = Enum.reverse(params)
      Enum.reduce(rest,
                  Lambda.create(fst, body),
                  fn(param, lambda_acc) -> Lambda.create(param, lambda_acc) end)
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

  def eval([:lambda, _, _, _] = lambda) do
    lambda
  end

  def eval([:let, sym, val, body]) do
    eval [Lambda.create(sym, body), eval(val)]
  end

  # TODO: local env captured??
  def eval([:freeze, expr]) do
    Lambda.create(nil, expr)
  end

  ##################### CONDITIONALS #############################

  def eval([:if, condition, consequent, alternative]) do
    if eval(condition) == true do
      eval(consequent)
    else
      eval(alternative)
    end
  end

  def eval([:cond, condition, consequent | rest]) do
    if [condition, consequent | rest] |> length |> Integer.is_odd do
      throw {:error, "Unbalanced cond clauses"}
    end

    if eval(condition) == true do
      eval(consequent)
    else
      eval([:cond | rest])
    end
  end

  def eval([:cond, _condition]) do
    throw {:error, "Unbalanced cond clause"}
  end

  def eval([:cond]) do
    throw {:error, "No matching cond clause"}
  end

  def eval([:and, arg1, arg2]) do
    eval(arg1) and eval(arg2)
  end

  def eval([:or, arg1, arg2]) do
    eval(arg1) or eval(arg2)
  end

  ###################### FUNCTION APPLICATION (PARTIAL) ####################

  def eval([f]) when is_atom(f) do
    if Map.has_key?(Primitives.mapping(), f) do
      Primitives.mapping()[f]
    else
      func = Env.lookup_function(f)
      if [:lambda, _, nil, body] = func do
        eval(body)
      else
        func
      end
    end
  end

  def eval([_]) do
    throw {:error, "Illegal function call"}
  end

  def eval(f) when is_function(f) do
    f.()
  end

  def eval([[:lambda, var, body], arg]) do
    eval [Lambda.create(var, body), arg]
  end

  def eval([[:lambda, _, _, _] = lambda, arg]) do
    eval Lambda.beta_reduce(lambda, eval(arg))
  end

  def eval([[_ | _] = f, arg]) do
    evaled_f = eval(f)
    evaled_arg = eval(arg)

    cond do
      is_function(evaled_f) -> evaled_f.(evaled_arg)
      [:lambda | _] = evaled_f -> eval [evaled_f, evaled_arg]
      Map.has_key?(Primitives.mapping(), evaled_f) ->
        func = Primitives.mapping()[evaled_f]
        func.(evaled_arg)
      true -> eval [Env.lookup_function(evaled_f), eval(evaled_arg)]
    end
  end

  def eval([f | args]) do
    # eval [[[f], arg1], arg2] ... or
    # eval [[[lambda x [lambda y ...]], arg1] arg2]
    f_expr = if match?([:lambda | _], f), do: f, else: [f]
    eval(
      Enum.reduce(args, f_expr, fn(acc, el) -> [el, acc] end)
    )
  end

  ##########################################################################

  def eval(term) do
    term
  end
end
