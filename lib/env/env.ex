defmodule Lisp.Env do
  @moduledoc """
`   A GenServer that stores the values of all variables`
  """
  use GenServer
  alias Lisp.Types

  def start_link(vars) do
    GenServer.start_link(__MODULE__, {:ok, vars})
  end

  def lookup(pid, sym) do
    GenServer.call(pid, {:lookup, sym})
  end

  def defun(pid, sym, value) do
    GenServer.cast(pid, {:defun, sym, value})
  end

  def all_vars(pid) do
    GenServer.call(pid, :all_vars)
  end

  ## Callbacks

  def init({:ok, vars}) do
    {:ok, vars}
  end

  def handle_call({:lookup, sym}, _from, vars) do
    {:reply, Map.get(vars, sym), vars}
  end

  def handle_call(:all_vars, _from, vars) do
    {:reply, vars, vars}
  end

  def handle_cast({:defun, sym, value}, vars) do
    {:noreply, Map.put(vars, sym, value)}
  end
end
