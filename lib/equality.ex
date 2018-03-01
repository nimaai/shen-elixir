defmodule KL.Equality do
  alias KL.Types, as: T
  require IEx

  @spec equal?(T.kl_term, T.kl_term) :: boolean
  def equal?(x, y) when is_list(x) and is_list(y) do
    equal?(x, y) and equal?(tl(x), tl(y))
  end

  def equal?({:vector, x}, {:vector, y}) when is_pid(x) and is_pid(y) do
    p = Agent.get(x, fn(a) -> a end)
    q = Agent.get(y, fn(a) -> a end)
    cf_vectors(p, q, :array.size(p), :array.size(q))
  end

  def equal?({:stream, x}, {:stream, y}) when is_pid(x) and is_pid(y), do: x == y

  def equal?(x, y), do: x == y

  @spec cf_vectors(:array.array, :array.array, number, number) :: boolean
  defp cf_vectors(x, y, lx, ly) do
    lx == ly and cf_vectors_help(x, y, 0, lx - 1)
  end

  @spec cf_vectors_help(:array.array, :array.array, number, number) :: boolean
  defp cf_vectors_help(x, y, count, max) do
    cond do
      count == max ->
        equal?(:array.get(max, x), :array.get(max, y))
      equal?(:array.get(count, x), :array.get(count, y)) ->
        cf_vectors_help(x, y, count + 1, max)
      true -> false
    end
  end
end
