defmodule Klambda.Reader do
  def tokenise(expr) do
    expr
    |> String.replace(~r/([\(\)])/, " \\1 ")
    |> String.split
  end

  defp atomise(token) do
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

  def check_parens(tokens, stack \\ [])

  def check_parens([], []) do
    true
  end

  def check_parens([], [_|_]) do
    false
  end

  def check_parens(["(" | tokens], stack) do
    check_parens(tokens, ["(" | stack])
  end

  def check_parens([")" | _tokens], []) do
    false
  end

  def check_parens([")" | tokens], stack) do
    check_parens(tokens, Enum.drop(stack, 1))
  end

  def check_parens([_token | tokens], stack) do
    check_parens(tokens, stack)
  end

  #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  def skip_newlines(input) do
    if input == "\n" do
      new_input = IO.gets("")
      skip_newlines(new_input)
    else
      input
    end
  end
end
