defmodule Klambda.Bindings do
  @moduledoc """
`   A GenServer that stores the values of all variables`
  """
  use GenServer

  def start_link(vars) do
    GenServer.start_link(__MODULE__, {:ok, vars})
  end

  def lookup(pid, sym) do
    GenServer.call(pid, {:lookup, sym})
  end

  def define(pid, sym, value) do
    GenServer.cast(pid, {:define, sym, value})
  end

  def all(pid) do
    GenServer.call(pid, :all)
  end

  ## Callbacks

  def init({:ok, vars}) do
    {:ok, vars}
  end

  def handle_call({:lookup, sym}, _from, vars) do
    {:reply, Map.get(vars, sym), vars}
  end

  def handle_call(:all, _from, vars) do
    {:reply, vars, vars}
  end

  def handle_cast({:define, sym, value}, vars) do
    {:noreply, Map.put(vars, sym, value)}
  end
end
