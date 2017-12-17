defmodule Klambda.Reader do
  require IEx

  @moduledoc """
    Contains functions that read and evaluate Klambda code.
  """

  alias Klambda.Reader.Eval
  alias Klambda.Lambda
  alias Klambda.Cont
  alias Klambda.Cons
  alias Klambda.Vector

  def tokenise(expr) do
    expr
    |> String.replace(~r/([\(\)])/, " \\1 ")
    |> String.split
  end

  def atomise(token) do
    cond do
      # If the token contains whitespace, it's not a bloody token.
      token =~ ~r/\s/ ->
        throw {:error, "Unexpected whitespace found in token: #{token}"}
      # If the token contains digits separated by a decimal point
      token =~ ~r/^\d+\.\d+$/ ->
        String.to_float token
      # If the token contains only digits
      token =~ ~r/^\d+$/ ->
        String.to_integer token
      token == "true" ->
        true
      token == "false" ->
        false
      # If the token is enclosed in double quotes
      token =~ ~r/^".*"$/ ->
        String.slice(token, 1, String.length(token) - 2)
      # If the token is a valid identifier
      token =~ ~r/^[^\d\(\)\.',@#][^\(\)\.`',@#]*$/ ->
        String.to_atom token
      :else ->
        throw {:error, "Cannot parse token: #{token}"}
    end
  end

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  def read([]) do
    []
  end

  def read(["(" | _tokens] = all_tokens) do
    {fst, snd} = Enum.split(all_tokens, matching_paren_index(all_tokens))
    [read(Enum.drop(fst, 1)) | read(Enum.drop(snd, 1))]
  end

  def read([")" | _tokens]) do
    throw {:error, "Unexpected list delimiter while reading"}
  end

  def read([token | tokens]) do
    [atomise(token) | read(tokens)]
  end

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  defp matching_paren_index(tokens, type \\ {"(", ")"}) do
    tokens
    |> Enum.with_index
    |> Enum.drop(1)
    |> do_matching_paren_index([], type)
  end

  defp do_matching_paren_index([], _stack, _type) do
    nil
  end

  defp do_matching_paren_index([{open, _i} | tokens], stack, {open, _close} = type) do
    do_matching_paren_index(tokens, [open | stack], type)
  end

  defp do_matching_paren_index([{close, i} | _tokens], [], {_open, close}) do
    i
  end

  defp do_matching_paren_index([{close, _i} | tokens], stack, {_open, close} = type) do
    do_matching_paren_index(tokens, Enum.drop(stack, 1), type)
  end

  defp do_matching_paren_index([_token | tokens], stack, type) do
    do_matching_paren_index(tokens, stack, type)
  end

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  defp check_parens(tokens, stack \\ [])

  defp check_parens([], []) do
    true
  end

  defp check_parens([], [_|_]) do
    false
  end

  defp check_parens(["(" | tokens], stack) do
    check_parens(tokens, ["(" | stack])
  end

  defp check_parens([")" | _tokens], []) do
    false
  end

  defp check_parens([")" | tokens], stack) do
    check_parens(tokens, Enum.drop(stack, 1))
  end

  defp check_parens([_token | tokens], stack) do
    check_parens(tokens, stack)
  end

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  def lispy_print({:error, message}) do
    "ERROR: #{message}"
  end

  def lispy_print(list) when is_list(list) do
    list
    |> Enum.map(&lispy_print/1)
    |> Enum.join(" ")
    |> (fn s -> "[#{s}]" end).()
  end

  def lispy_print(str) when is_binary(str) do
    "\"" <> str <> "\""
  end

  def lispy_print(pid) when is_pid(pid) do
    inspect(pid)
  end

  def lispy_print(f) when is_function(f) do
    "<Function>"
  end

  def lispy_print(%Cont{} = cont) do
    Cont.to_string(cont)
  end

  def lispy_print(%Lambda{} = lambda) do
    Lambda.to_string(lambda)
  end

  def lispy_print(%Cons{} = cons) do
    Cons.to_string(cons, "[", "]")
  end

  def lispy_print({:array, pid}) do
    Vector.to_string(pid)
  end

  def lispy_print(:end_of_cons) do
    "[]"
  end

  def lispy_print(nil) do
    "nil"
  end

  def lispy_print(term) do
    to_string term
  end

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  defp skip_newlines(input) do
    if input == "\n" do
      new_input = IO.gets("")
      skip_newlines(new_input)
    else
      input
    end
  end

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  defp eval_catch(x, env) do
    try do
      Eval.eval(hd(x), env)
    catch
      e -> e
    end
  end

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  def read_input(env, num \\ 0, read_so_far \\ [], leading_text \\ nil) do
    leading_text = if is_nil(leading_text) do
      "klambda(#{num})> "
    else
      leading_text
    end

    tokens =
      leading_text
      |> IO.gets
      |> skip_newlines
      |> tokenise

    cond do
      tokens == [":quit"] ->
        nil
      not check_parens(read_so_far ++ tokens) ->
        read_input(env, num, read_so_far ++ tokens, "")
      :else ->
        read_so_far
        |> Kernel.++(tokens)
        |> read
        |> eval_catch(env)
        |> lispy_print
        |> IO.puts

        read_input(env, num + 1, [])
    end
  end
end
