defmodule KL.Env do
  alias KL.Bindings, as: B
  alias KL.Primitives, as: P
  require IEx

  def init do
    func = fn ->
      {:ok, f_pid} = B.start_link(P.mapping)
      {:ok, g_pid}= B.start_link(
        %{"*stinput*": :stdio,
          "*stoutput*": :stdio,
          "*home-directory*": "" # really???
        }
      )

      %{globals: g_pid,
        functions: f_pid,
        start_time: DateTime.utc_now() |> DateTime.to_unix()
      }
    end
    Agent.start_link(func, name: :env)
  end

  def lookup_global(sym) do
    B.lookup(
      Agent.get(:env, fn state -> state[:globals] end),
      sym
    )
  end

  def define_global(sym, val) do
    B.define(
      Agent.get(:env, fn state -> state[:globals] end),
      sym,
      val
    )
  end

  def lookup_function(sym) do
    %{functions: pid} = Agent.get(:env, fn state -> state end)
    gf = B.lookup(pid, sym)
    if is_nil(gf) do
      throw {:error, "Undefined function #{sym}"}
    else
      gf
    end
  end

  def define_function(sym, fn_body) do
    B.define(
      Agent.get(:env, fn state -> state[:functions] end),
      sym,
      fn_body
    )
  end
end
