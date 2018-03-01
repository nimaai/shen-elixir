defmodule KL.Repl do
  alias KL.Reader
  alias KL.Eval
  require IEx

  def repl(num \\ 0, read_so_far \\ [], leading_text \\ nil) do
    leading_text = if is_nil(leading_text) do
      "kl(#{num})> "
    else
      leading_text
    end

    tokens =
      leading_text
      |> IO.gets
      |> skip_newlines
      |> Reader.tokenise

    v = if not Reader.check_parens(read_so_far ++ tokens) do
      repl(num, read_so_far ++ tokens, "")
    else
      read_so_far
      |> Kernel.++(tokens)
      |> Reader.read
      |> eval_rescue
    end

    cond do
      match?(%KL.SimpleError{}, v) ->
        IO.puts(v.message)
        IO.binwrite("\n")
      Exception.exception?(v) -> Exception.format(:error, v) |> IO.puts
      true ->
        v |> inspect |> IO.puts
        IO.binwrite("\n")
    end

    repl(num + 1, [])
  end

  defp eval_rescue(x) do
    try do
      Eval.eval(hd(x), %{})
    rescue
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
Process.flag(:trap_exit, true)
KL.Env.init
KL.Repl.repl
