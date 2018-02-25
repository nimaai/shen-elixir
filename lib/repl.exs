defmodule KL.Repl do
  alias KL.Reader
  alias KL.Eval
  alias KL.Print
  require IEx

  def repl(num \\ 0, read_so_far \\ [], leading_text \\ nil) do
    leading_text = if is_nil(leading_text) do
      "klambda(#{num})> "
    else
      leading_text
    end

    tokens =
      leading_text
      |> IO.gets
      |> skip_newlines
      |> Reader.tokenise

    if not Reader.check_parens(read_so_far ++ tokens) do
      repl(num, read_so_far ++ tokens, "")
    else
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
      Eval.eval(hd(x), %{})
    catch
      e -> e
    end
  end

  defp skip_newlines(input) do
    if input == "\n" do
      new_input = IO.gets("")
      skip_newlines(new_input)
    else
      input
    end
  end
end

# :dbg.tracer()
# :dbg.p(:all, :c)
# :dbg.tpl(KL.Eval, :eval, 2, :x)
KL.Env.init
KL.Repl.repl
