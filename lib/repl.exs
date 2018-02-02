defmodule Repl do
  alias Klambda.Reader
  alias Klambda.Eval
  alias Klambda.Print

  def repl(num \\ 0, read_so_far \\ [], leading_text \\ nil) do
    leading_text = if is_nil(leading_text) do
      "klambda(#{num})> "
    else
      leading_text
    end

    tokens =
      leading_text
      |> IO.gets
      |> Reader.skip_newlines
      |> Reader.tokenise

    cond do
      tokens == [":quit"] ->
        nil
      not Reader.check_parens(read_so_far ++ tokens) ->
        repl(num, read_so_far ++ tokens, "")
      :else ->
        read_so_far
        |> Kernel.++(tokens)
        |> Reader.read
        |> eval_catch
        |> Print.print
        |> IO.puts

        repl(num + 1, [])
    end
  end

  defp eval_catch(x) do
    try do
      Eval.eval(hd(x))
    catch
      e -> e
    end
  end
end

Klambda.Env.init
Repl.repl
