defmodule KL.Env do
  alias KL.Bindings, as: B
  alias KL.Primitives, as: P
  alias KL.Types, as: T
  require IEx

  @spec init :: {:error, any} | {:ok, pid}
  def init do
    f = fn ->
      {:ok, fp} = B.start_link(P.mapping)
      {:ok, gp}= B.start_link(%{
        "*stinput*": :stdio,
        "*stoutput*": :stdio,
        "*home-directory*": ""
      })

      %{vars: gp,
        fns: fp,
        start_time: DateTime.utc_now() |> DateTime.to_unix()}
    end
    Agent.start_link(f, name: :env)
  end

  @spec get_var(atom) :: T.kl_term
  def get_var(n) when is_atom(n) do
    B.lookup(Agent.get(:env, fn(env) -> env[:vars] end), n)
  end

  @spec set_var(atom, T.kl_term) :: :ok
  def set_var(n, v) when is_atom(n) do
    B.define(Agent.get(:env, fn(env) -> env[:vars] end), n, v)
  end

  @spec get_fn(atom) :: function | Exception.t
  def get_fn(n) when is_atom(n) do
    fp = Agent.get(:env, fn(env) -> env[:fns] end)
    f = B.lookup(fp, n)
    if is_nil(f), do: raise("the function #{inspect(n)} is undefined"), else: f
  end

  @spec set_fn(atom, function) :: :ok
  def set_fn(n, f) when is_atom(n) and is_function(f) do
    B.define(Agent.get(:env, fn(env) -> env[:fns] end), n, f)
  end
end
