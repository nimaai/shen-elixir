defmodule Klambda.Env do
  alias Klambda.Bindings
  alias Klambda.Lambda
  alias Klambda.Primitives
  require IEx

  def init do
    func = fn ->
      {:ok, functions_pid} = Bindings.start_link(Primitives.mapping)
      {:ok, globals_pid}= Bindings.start_link(
        %{"*stinput*": :stdio,
          "*stoutput*": :stdio,
          "*home-directory*": "" # really???
        }
      )

      %{globals: globals_pid,
        functions: functions_pid,
        start_time: DateTime.utc_now() |> DateTime.to_unix()
      }
    end
    Agent.start_link(func, name: :env)
  end

  def lookup_global(sym) do
    Bindings.lookup(
      Agent.get(:env, fn state -> state[:globals] end),
      sym
    )
  end

  def define_global(sym, val) do
    Bindings.define(
      Agent.get(:env, fn state -> state[:globals] end),
      sym,
      val
    )
  end

  def lookup_function(sym) do
    %{functions: pid} = Agent.get(:env, fn state -> state end)
    gf = Bindings.lookup(pid, sym)
    if is_nil(gf) do
      throw {:error, "Undefined function #{sym}"}
    else
      gf
    end
  end

  def define_function(sym, [:lambda | _] = lambda) do
    Bindings.define(
      Agent.get(:env, fn state -> state[:functions] end),
      sym,
      lambda
    )
  end
end
