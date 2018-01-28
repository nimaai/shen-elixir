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
                          [:lambda, fst | body],
                          fn(param, lambda_acc) -> [:lambda, param, lambda_acc] end)
    :ok = Env.define_function(fn_name, curried)
    fn_name
  end

  def eval([:lambda, param, body] = lambda) do
    if is_atom(param) do
      lambda
    else
      throw {:error, "Required argument is not a symbol"}
    end
  end

  def eval([:let, sym, val, body]) do
    eval [[:lambda, sym, body], eval(val)]
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

  def eval(f) when is_function(f) do
    f.()
  end

  def eval([[:lambda, var, body] = lambda, arg]) do
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

  # ############################ ARRAYS #####################################

  # def eval([:absvector, arg], env) do
  #   evaled_arg = eval(arg, env)
  #   Vector.new(evaled_arg)
  # end

  # def eval([:"address->", arg, pos, val], env) do
  #   evaled_vec = eval(arg, env)
  #   evaled_pos = eval(pos, env)
  #   evaled_val = eval(val, env)
  #   Vector.set(evaled_vec, evaled_pos, evaled_val)
  # end

  # def eval([:"<-address", arg, pos], env) do
  #   evaled_vec = eval(arg, env)
  #   evaled_pos = eval(pos, env)
  #   Vector.get(evaled_vec, evaled_pos)
  # end

  # def eval([:"absvector?", arg], env) do
  #   match?( {:array, _}, eval(arg, env) )
  # end

  # ############################ CONSES #####################################

  # def eval([:"cons?", arg], env) do
  #   match?( %Cons{}, eval(arg, env) )
  # end

  # def eval([:cons, head, tail], env) do
  #   evaled_head = eval(head, env)
  #   evaled_tail = eval(tail, env)
  #   %Cons{
  #     head: evaled_head,
  #     tail: if match?( [], evaled_tail ) do
  #       :end_of_cons
  #     else
  #       evaled_tail
  #     end
  #   }
  # end

  # def eval([:hd, arg], env) do
  #   evaled_arg = eval(arg, env)
  #   case evaled_arg do
  #     %Cons{head: head} -> head
  #     _ -> throw {:error, "Argument is not a cons"}
  #   end
  # end

  # def eval([:tl, arg], env) do
  #   evaled_arg = eval(arg, env)
  #   case evaled_arg do
  #     %Cons{tail: tail} -> tail
  #     _ -> throw {:error, "Argument is not a cons"}
  #   end
  # end

  # ############################ STREAMS ####################################

  # def eval([:"write-byte", num, stream], env) do
  #   # TODO: raise error if stream closed or on in out mode
  #   evaled_num = eval(num, env)
  #   evaled_stream = eval(stream, env)
  #   :ok = IO.binwrite( evaled_stream, to_string(<<evaled_num>>) )
  #   evaled_num
  # end

  # def eval([:"read-byte", stream], env) do
  #   # TODO: raise error if stream closed or on in in mode
  #   evaled_stream = eval(stream, env)
  #   char = IO.binread( evaled_stream, 1 )
  #   <<num, _>> = char <> <<0>>
  #   case num do
  #     :oef -> -1
  #     _ -> num
  #   end
  # end

  # def eval([:open, path, mode], env) do
  #   evaled_path = eval(path, env)
  #   evaled_mode = case eval(mode, env) do
  #     :in -> :read
  #     :out -> :write
  #     _ -> {:"simple-error", "invalid mode"}
  #   end
  #   {:ok, pid} = File.open( evaled_path, [evaled_mode] )
  #   pid
  # end

  # def eval([:close, stream], env) do
  #   evaled_stream = eval(stream, env)
  #   true = Process.exit( evaled_stream, :kill )
  #   []
  # end

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

  # ################################## PRIVATE FUNCTIONS ##############################

  # defp equal?(arg1, arg2) when is_number(arg1) and is_number(arg2) do
  #   arg1 == arg2
  # end

  # defp equal?(arg1, arg2) when is_binary(arg1) and is_binary(arg2) do
  #   arg1 == arg2
  # end

  # defp equal?(arg1, arg2) when is_atom(arg1) and is_atom(arg2) do
  #   arg1 == arg2
  # end

  # defp equal?(%Cons{head: head1, tail: tail1}, %Cons{head: head2, tail: tail2}) do
  #   equal?(head1, head2) && equal?(tail1, tail2)
  # end

  # defp equal?(arg1, arg2) when is_function(arg1) and is_function(arg2) do
  #   arg1 == arg2
  # end

  # defp equal?(arg1, arg2) when is_function(arg1) and is_function(arg2) do
  #   arg1 == arg2
  # end

  # defp equal?(%Lambda{id: id1}, %Lambda{id: id2}) do
  #   id1 == id2
  # end

  # defp equal?(arg1, arg2) when is_pid(arg1) and is_pid(arg2) do
  #   arg1 == arg2
  # end

  # defp equal?(_arg1, _arg2) do
  #   false
  # end

  # def curry(f, arity) do
  #   params = [first | rest] = Enum.map(arity..1, fn(count) -> :"x#{count}" end)
  #   Enum.reduce(
  #     rest,
  #     [:lambda, first, [f | Enum.reverse(params)]],
  #     fn(param, lambda_acc) -> [:lambda, param, lambda_acc] end
  #   )
  # end
end
