defmodule Klambda.Reader.Eval do
  alias Klambda.Lambda
  alias Klambda.Continuation
  alias Klambda.Cons
  alias Klambda.Env
  alias Klambda.Vector
  alias Klambda.Primitives
  require IEx
  require Integer

  # TODO: check eval args in function calls !
  # TODO: raise error on arg type mismatch !

  ##################### FUNCTIONS AND BINDINGS ###################

  def eval([:defun, fn_name, params | body]) when is_atom(fn_name) do
    [fst | rest] = Enum.reverse(params)
    curried = Enum.reduce(rest,
                          Lambda.create(fst, body),
                          fn(param, lambda_acc) -> Lambda.create(param, lambda_acc) end)
    :ok = Env.define_function(fn_name, curried |> IO.inspect)
    fn_name
  end

  def eval([:lambda, param, body]) do
    if is_atom(param) do
      Lambda.create(param, body)
    else
      throw {:error, "Required argument is not a symbol"}
    end
  end

  def eval([:let, sym, val, body]) do
    eval [Lambda.create(sym, body), eval(val)]
  end

  def eval([:freeze, expr]) do
    expr
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
    cond do
      Map.has_key?(Primitives.mapping(), f) -> Primitives.mapping()[f]
      true -> Env.lookup_function(f)
    end
  end

  def eval([_]) do
    throw {:error, "Illegal function call"}
  end

  def eval(f) when is_function(f) do
    f.()
  end

  def eval([[:lambda, _, var, body] = lambda, arg]) do
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

  # ############################ GENERAL ####################################

  # def eval([:"=", arg1, arg2], env) do
  #   equal?( eval(arg1, env), eval(arg2, env) )
  # end

  # def eval([:"eval-kl", [:cons | _] = arg], env) do
  #   evaled_arg = eval(arg, env)
  #   eval( Cons.to_list( evaled_arg ), env )
  # end

  # ####################### INFORMATIONAL ###################################

  # def eval([:"get-time", arg], env) do
  #   evaled_arg = eval(arg, env)
  #   now = DateTime.utc_now() |> DateTime.to_unix()
  #   case evaled_arg do
  #     :unix -> now
  #     :run -> now - env[:start_time]
  #     _ -> throw {:error, "invalid symbol for get-time"}
  #   end
  # end

  # def eval([:type, arg, _sym], env) do
  #   eval(arg, env)
  # end

  # #########################################################################

  # # def eval([f | args], env) do
  # #   fun = case f do
  # #     f when is_atom(f) -> Env.lookup_function(env, f)
  # #     f = [:lambda | _] -> eval(f, env)
  # #   end

  # #   evaled_args = Enum.map(args, &eval(&1, env))
  # #   eval_function_call(fun, evaled_args, env)
  # # end

  def eval(term) when is_boolean(term) do
    term
  end

  def eval(term) when is_atom(term) do
    locals = Agent.get(:env, fn state -> state[:locals] end)
    val = locals[term]
    if is_nil(val) do
      term
    else
      val
    end
  end

  def eval(term) do
    term
  end
end
