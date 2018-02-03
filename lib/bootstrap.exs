alias Klambda.Env

defmodule Shen.Bootstrap do
  alias Klambda.Reader
  alias Klambda.Eval
  require IEx

  def read_and_eval_kl_file(path) do
    Agent.start_link(fn -> [] end, name: :buffer)
    {:ok, f} = File.open(path, [:read])
    :ok = skip_copyright(f)
    read_and_eval_form(f)
  end

  def read_and_eval_form(f) do
    c = getc(f)
    if c == :eof do
      :ok
    else
      :ok = skip_newlines(f)
      {"", form} = read_form(f)
      form
      |> Reader.tokenise
      |> hd
      |> Eval.eval
      |> read_and_eval_form
    end
  end

  defp read_form(_, read_so_far \\ nil, paren_count \\ 0)

  defp read_form(file, nil, 0) do
    {:ok, read_so_far} = StringIO.open("")
    read_form(file, read_so_far, 0)
  end

  defp read_form(file, read_so_far, paren_count) do
    if parent_count == 0 do
      StringIO.contents(read_so_far)
    else
      c = getc(file)
      :ok = IO.binwrite(read_so_far, c)
      read_form(
        file,
        read_so_far,
        case c do
          "(" -> paren_count + 1
          ")" -> paren_count - 1
          _ -> paren_count
        end
      )
    end
  end

  defp skip_copyright(f, within \\ false) do
    c = getc(f)
    cond do
      c == "\"" and not within -> skip_copyright(f, true)
      c != "\"" and within -> skip_copyright(f, true)
      true -> :ok
    end
  end

  defp skip_newlines(f) do
    c = getc(f)
    if c == "\n" do
      skip_newlines(f)
    else
      buf(c)
    end
  end

  defp getc(f) do
    c = Agent.get_and_update(:buffer, fn(b) -> List.pop_at(b, 1) end)
    c || IO.binread(f, 1)
  end

  defp buf(c) do
    Agent.update(:buffer, fn(b) -> [c] ++ b end)
  end
end

Env.init
Shen.Bootstrap.read_and_eval_kl_file("klambda-sources/core.kl")
