alias Klambda.Env

defmodule Shen.Bootstrap do
  alias Klambda.Reader
  alias Klambda.Eval
  require IEx

  def read_and_eval_kl_file(path) do
    {:ok, f} = File.open(path, [:read])
    f |> skip_copyright |> read_and_eval_form
  end

  def read_and_eval_form(f) do
    f
    |> read_form
    |> hd
    |> Eval.eval
    |> read_and_eval_form
  end

  defp read_form(file, read_so_far \\ []) do
    tokens =
      file
      |> skip_newlines
      |> Reader.tokenise

    if not Reader.check_parens(read_so_far ++ tokens) do
      read_form(file, read_so_far ++ tokens)
    else
      read_so_far
      |> Kernel.++(tokens)
      |> Reader.read
    end
  end

  defp skip_copyright(f, within \\ false) do
    char = IO.binread(f, 1)
    cond do
      char == "\"" and not within -> skip_copyright(f, true)
      char != "\"" and within -> skip_copyright(f, true)
      true -> f
    end
  end

  defp skip_newlines(f) do
    line = IO.gets(f, "")
    if line == "\n" do
      skip_newlines(f)
    else
      line
    end
  end
end

Env.init
Shen.Bootstrap.read_and_eval_kl_file("klambda-sources/core.kl")
