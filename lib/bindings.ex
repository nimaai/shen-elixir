defmodule KL.Bindings do
  use GenServer
  alias KL.Types, as: T

  def start_link(m) do
    GenServer.start_link(__MODULE__, {:ok, m})
  end

  @spec lookup(pid, atom) :: T.kl_term
  def lookup(p, n), do: GenServer.call(p, {:lookup, n})

  @spec define(pid, atom, T.kl_term) :: :ok
  def define(p, n, v), do: GenServer.cast(p, {:define, n, v})

  @spec all(pid) :: map
  def all(p), do: GenServer.call(p, :all)

  ## Callbacks

  @spec handle_call({:lookup, atom} | :all, any, atom) :: {:reply, map | T.kl_term, map}
  def handle_call({:lookup, n}, _, m), do: {:reply, Map.get(m, n), m}
  def handle_call(:all, _, m), do: {:reply, m, m}

  @spec handle_cast({:define, atom, T.kl_term}, map) :: {:noreply, map}
  def handle_cast({:define, n, v}, m), do: {:noreply, Map.put(m, n, v)}
end
