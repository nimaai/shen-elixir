defmodule Klambda.Reader.Eval do
  alias Klambda.Lambda
  alias Klambda.Cont
  alias Klambda.Cons
  alias Klambda.Env
  alias Klambda.Vector
  require IEx
  require Integer


  # TODO: check eval args in function calls !
  # TODO: raise error on arg type mismatch !

  ########################## FUNCTIONS AND BINDINGS #######################

  def eval([:defun, func, params | body], env) do
    :ok = Env.define_function( env, func, Lambda.create(params, body) )
    func
  end

  def eval([:lambda, param | body], _env) do
    if is_atom(param) do
      Lambda.create([param], body)
    else
      throw {:error, "Required argument is not a symbol"}
    end
  end

  def eval([:let, sym, value_expr | body], env) do
    Lambda.call(
      Lambda.create([sym], body),
      [eval(value_expr, env)],
      env
    )
  end

  def eval([:freeze, body], env) do
    %Cont{body: body, locals: env[:locals]}
  end

  # NOTE: not needed for klambda
  def eval([:function, func], env) do
    Env.lookup_function(func, env)
  end

  #########################################################################

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

  def eval([:"trap-error", body, handler], env) do
    result = eval(body, env)
    case result do
      exception = {:"simple-error", _message} ->
        eval([handler, exception], env)
      true -> result
    end
  end

  def eval([:"simple-error", message], _env) do
    throw {:"simple-error", message}
  end

  def eval([:"error-to-string", [:"simple-error", message]], _env) do
    message
  end

  def eval([:set, sym, value], env) do
    evaled_value = eval(value, env)
    :ok = Env.define_global(env, sym, evaled_value)
    evaled_value
  end

  def eval([:value, global_var], env) do
    Env.lookup_global(env, global_var)
  end

  def eval([:intern, name], _env) do
    String.to_atom(name)
  end

  ################################ STRINGS ################################

  def eval([:string?, arg], _env) do
    is_bitstring(arg)
  end

  def eval([:pos, arg, n], _env) do
    unit = String.at(arg, n)
    if is_nil(unit) do
      throw {:error, "String index is out bounds"}
    else
      unit
    end
  end

  def eval([:tlstr, arg], _env) do
    if String.length(arg) == 0 do
      throw {:error, "Argument is empty string"}
    else
      {_, tlstr} = String.split_at(arg, 1)
      tlstr
    end
  end

  def eval([:cn, s1, s2], _env) do
    s1 <> s2
  end

  def eval([:str, arg], env) do
    evaled_arg = eval(arg, env)
    cond do
      is_bitstring(evaled_arg) -> "\"" <> evaled_arg <> "\""
      %Lambda{} = evaled_arg -> Lambda.to_string(evaled_arg)
      %Cont{} = evaled_arg -> Cont.to_string(evaled_arg)
      true -> to_string(evaled_arg)
    end
  end

  def eval([:"string->n", arg], env) do
    evaled_arg = eval(arg, env)
    if String.length(evaled_arg) == 0 do
      throw {:error, "Argument is empty string"}
    else
      List.first(String.to_charlist(evaled_arg))
    end
  end

  def eval([:"n->string", arg], env) do
    evaled_arg = eval(arg, env)
    if String.valid? <<evaled_arg>> do
       <<evaled_arg>>
    else
      throw {:error, "Not a valid codepoint"}
    end
  end

  ############################ ARRAYS #####################################

  def eval([:absvector, arg], env) do
    evaled_arg = eval(arg, env)
    Vector.new(evaled_arg)
  end

  def eval([:"address->", arg, pos, val], env) do
    evaled_vec = eval(arg, env)
    evaled_pos = eval(pos, env)
    evaled_val = eval(val, env)
    Vector.set(evaled_vec, evaled_pos, evaled_val)
  end

  def eval([:"<-address", arg, pos], env) do
    evaled_vec = eval(arg, env)
    evaled_pos = eval(pos, env)
    Vector.get(evaled_vec, evaled_pos)
  end

  def eval([:"absvector?", arg], env) do
    match?( {:array, _}, eval(arg, env) )
  end

  ############################ CONSES #####################################

  def eval([:"cons?", arg], env) do
    match?( %Cons{}, eval(arg, env) )
  end

  def eval([:cons, head, tail], env) do
    evaled_head = eval(head, env)
    evaled_tail = eval(tail, env)
    %Cons{
      head: evaled_head,
      tail: if match?( [], evaled_tail ) do
        :end_of_cons
      else
        evaled_tail
      end
    }
  end

  def eval([:hd, arg], env) do
    evaled_arg = eval(arg, env)
    case evaled_arg do
      %Cons{head: head} -> head
      _ -> throw {:error, "Argument is not a cons"}
    end
  end

  def eval([:tl, arg], env) do
    evaled_arg = eval(arg, env)
    case evaled_arg do
      %Cons{tail: tail} -> tail
      _ -> throw {:error, "Argument is not a cons"}
    end
  end

  ############################ STREAMS ####################################

  def eval([:"write-byte", num, stream], env) do
    # TODO: raise error if stream closed or on in out mode
    evaled_num = eval(num, env)
    evaled_stream = eval(stream, env)
    :ok = IO.binwrite( evaled_stream, to_string(<<evaled_num>>) )
    evaled_num
  end

  def eval([:"read-byte", stream], env) do
    # TODO: raise error if stream closed or on in in mode
    evaled_stream = eval(stream, env)
    char = IO.binread( evaled_stream, 1 )
    <<num, _>> = char <> <<0>>
    case num do
      :oef -> -1
      _ -> num
    end
  end

  def eval([:open, path, mode], env) do
    evaled_path = eval(path, env)
    evaled_mode = case eval(mode, env) do
      :in -> :read
      :out -> :write
      _ -> {:"simple-error", "invalid mode"}
    end
    {:ok, pid} = File.open( evaled_path, [evaled_mode] )
    pid
  end

  def eval([:close, stream], env) do
    evaled_stream = eval(stream, env)
    true = Process.exit( evaled_stream, :kill )
    []
  end

  ############################ GENERAL ####################################

  def eval([:"=", arg1, arg2], env) do
    equal?( eval(arg1, env), eval(arg2, env) )
  end

  def eval([:"eval-kl", [:cons | _] = arg], env) do
    evaled_arg = eval(arg, env)
    eval( Cons.to_list( evaled_arg ), env )
  end

  ####################### INFORMATIONAL ###################################

  def eval([:"get-time", arg], env) do
    evaled_arg = eval(arg, env)
    now = DateTime.utc_now() |> DateTime.to_unix()
    case evaled_arg do
      :unix -> now
      :run -> now - env[:start_time]
      _ -> throw {:error, "invalid symbol for get-time"}
    end
  end

  #########################################################################

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
    if is_nil(val) do
      term
    else
      val
    end
  end

  def eval(term, _env) do
    term
  end

  ################################## PRIVATE FUNCTIONS ##############################

  defp eval_function_call(%Lambda{} = f, args, env) do
    Lambda.call(f, args, env)
  end

  defp eval_function_call(f, args, _env) when is_function(f) do
    apply(f, args)
  end

  defp equal?(arg1, arg2) when is_number(arg1) and is_number(arg2) do
    arg1 == arg2
  end

  defp equal?(arg1, arg2) when is_binary(arg1) and is_binary(arg2) do
    arg1 == arg2
  end

  defp equal?(arg1, arg2) when is_atom(arg1) and is_atom(arg2) do
    arg1 == arg2
  end

  defp equal?(%Cons{head: head1, tail: tail1}, %Cons{head: head2, tail: tail2}) do
    equal?(head1, head2) && equal?(tail1, tail2)
  end

  defp equal?(arg1, arg2) when is_function(arg1) and is_function(arg2) do
    arg1 == arg2
  end

  defp equal?(arg1, arg2) when is_function(arg1) and is_function(arg2) do
    arg1 == arg2
  end

  defp equal?(%Lambda{id: id1}, %Lambda{id: id2}) do
    id1 == id2
  end

  defp equal?(arg1, arg2) when is_pid(arg1) and is_pid(arg2) do
    arg1 == arg2
  end

  defp equal?(_arg1, _arg2) do
    false
  end
end
