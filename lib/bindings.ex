defmodule KL.Bindings do
  use GenServer
  alias KL.Types, as: T

  def start_link(m) do
    GenServer.start_link(__MODULE__, {:ok, m})
  end

  @spec lookup(pid, atom) :: T.kl_term
  def lookup(p, k), do: GenServer.call(p, {:lookup, k})

  @spec define(pid, atom, T.kl_term) :: :ok
  def define(p, k, v), do: GenServer.cast(p, {:define, k, v})

  @spec all(pid) :: map
  def all(p), do: GenServer.call(p, :all)

  ## Callbacks

  @spec init({:ok, map}) :: {:ok, map}
  def init({:ok, m}), do: {:ok, m}

  @spec handle_call({:lookup, atom} | :all, any, atom) :: {:reply, map | T.kl_term, map}
  def handle_call({:lookup, k}, _, m), do: {:reply, Map.get(m, k), m}
  def handle_call(:all, _, m), do: {:reply, m, m}

  @spec handle_cast({:define, atom, T.kl_term}, map) :: {:noreply, map}
  def handle_cast({:define, k, v}, m), do: {:noreply, Map.put(m, k, v)}
end
