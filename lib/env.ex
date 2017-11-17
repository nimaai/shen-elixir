defmodule Klambda.Env do
  alias Klambda.Bindings
  alias Klambda.Lambda
  alias Klambda.Primitives
  require IEx

  def init do
    {:ok, functions_pid} = Bindings.start_link(Primitives.mapping)
    {:ok, globals_pid}= Bindings.start_link(
      %{"*stinput*": :stdio,
        "*stoutput*": :stdio,
        "*home-directory*": "" # really???
      }
    )

    %{locals: %{},
      globals: globals_pid,
      functions: functions_pid,
      start_time: DateTime.utc_now() |> DateTime.to_unix()
    }
  end

  def lookup_global(%{globals: pid}, sym) do
    Bindings.lookup(pid, sym)
  end

  def define_global(%{globals: pid}, sym, val) do
    Bindings.define(pid, sym, val)
  end

  def lookup_function(%{functions: pid, locals: locals}, sym) do
    gf = Bindings.lookup(pid, sym)
    if is_nil(gf) do
      lf = locals[sym]
      if is_nil(lf) do
        throw {:error, "Undefined function #{sym}"}
      end
    else
      gf
    end
  end

  def define_function(%{functions: pid}, sym, lambda = %Lambda{}) do
    Bindings.define(pid, sym, lambda)
  end
end
