alias Kl.Env
alias Kl.Eval

defmodule Shen.Bootstrap do
  alias Kl.Reader
  require IEx

  def read_and_eval_kl_file(path) do
    Agent.start_link(fn -> [] end, name: :buffer)
    {:ok, f} = File.open(path, [:read])
    :ok = skip_copyright(f)
    :ok = read_and_eval_form(f)
  end

  def read_and_eval_form(file_iod) do
    :ok = skip_newlines(file_iod)
    c = getc(file_iod)
    if c == :eof do
      :ok
    else
      ungetc(c)
      {:ok, form_iod} = StringIO.open("")
      {"", form} = read_form(file_iod, form_iod, 0, 0)
      eval_form(form)
      read_and_eval_form(file_iod)
    end
  end

  def eval_form(form) do
    form
    # |> IO.inspect
    |> Reader.tokenise
    |> Reader.read
    |> hd
    |> Eval.eval(%{})
  end

  defp read_form(file, form_iod, left, right) do
    if left == right and left > 0 and right > 0 do
      StringIO.contents(form_iod)
    else
      c = getc(file)
      :ok = IO.binwrite(form_iod, c)
      case c do
        "(" -> read_form(file, form_iod, left + 1, right)
        ")" -> read_form(file, form_iod, left, right + 1)
        _ -> read_form(file, form_iod, left, right)
      end
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
      :ok = ungetc(c)
    end
  end

  defp getc(f) do
    c = Agent.get_and_update(:buffer, fn(b) -> List.pop_at(b, 0) end)
    c || IO.binread(f, 1)
  end

  defp ungetc(c) do
    Agent.update(:buffer, fn(b) -> [c] ++ b end)
  end
end

Env.init
# :dbg.tracer()
# :dbg.p(:all, :c)
# :dbg.tp(Kl.Eval, :eval, 2, :x)
start_time = DateTime.utc_now |> DateTime.to_unix
Enum.each(
  [
    "toplevel.kl",
    "core.kl",
    "sys.kl",
    "sequent.kl",
    "yacc.kl",
    "reader.kl",
    "prolog.kl",
    "track.kl",
    "load.kl",
    "writer.kl",
    "macros.kl",
    "declarations.kl",
    "t-star.kl",
    "types.kl"
  ],
  fn(file) ->
    IO.puts("loading: #{file}")
    Shen.Bootstrap.read_and_eval_kl_file("kl-sources/#{file}")
  end
)
end_time = DateTime.utc_now |> DateTime.to_unix
IO.puts("loaded in #{end_time - start_time} seconds")
# Eval.eval([:"shen.shen"])
