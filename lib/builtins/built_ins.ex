defmodule Lisp.BuiltIns do
  @moduledoc """
    Contains built-in functions that would be tedious for users to constantly
    implement for themselves.
    For the most part, contains functions that would be incredibly hard to
    implement without relying on another language.
    Functions that are possible to define in Lixp are found in modules.
  """
  alias Lisp.Types

  @doc """
    Executes several forms one after the other and returns the value of the
    last form. (The other forms are expected to contain side effects.)
  """
  @spec begin([Types.valid_term]) :: Types.valid_term
  defp begin([]) do
    nil
  end
  defp begin([arg]) do
    arg
  end
  defp begin([_arg | args]) do
    begin args
  end

  @spec add([integer | float]) :: integer | float
  defp add(args) do
    Enum.reduce args, 0, &+/2
  end

  @spec subtract([integer | float]) :: integer | float
  defp subtract(args) do
    Enum.reduce args, 0, fn(x, acc) -> acc - x end
  end

  @spec multiply([integer | float]) :: integer | float
  defp multiply(args) do
    Enum.reduce args, 1, &*/2
  end

  @spec divide([integer | float]) :: float
  defp divide([]), do: 1.0
  defp divide(args) do
    Enum.reduce args, fn(x, acc) -> acc / x end
  end

  @spec pow([integer | float]) :: float
  def pow([]), do: 1.0
  def pow(args) do
    args
    # Exponentiation is right associative, so you have to reverse it first.
    |> Enum.reverse
    # In this case, "&:math.pow/2" is way too hard to read and understand.
    |> Enum.reduce(fn(x, acc) -> :math.pow(x, acc) end)
  end

  @spec equal([any]) :: boolean
  def equal([]), do: false
  def equal([arg | _args] = all_args) do
    Enum.all? all_args, fn x -> x == arg end
  end

  @spec not_equal([any]) :: boolean
  def not_equal(args), do: not equal(args)

  @spec display([String.t]) :: :ok
  defp display(args) do
    :ok = args
    |> Enum.join(" ")
    |> IO.write
  end

  @spec newline([]) :: :ok
  defp newline, do: newline([])
  defp newline([]) do
    display(["\n"])
  end

  @spec displayln([String.t]) :: :ok
  defp displayln(args) do
    display(args)
    newline
  end

  @doc """
    Returns a hashmap that maps Lisp symbols (e.g. 'begin, '+, 'display) to the
    corresponding Elixir function.
  """
  def std_env do
    %{+: &add/1,
      -: &subtract/1,
      *: &multiply/1,
      /: &divide/1,
      ^: &pow/1,
      =: &equal/1,
      "/=": &not_equal/1,
      begin: &begin/1,
      display: &display/1,
      newline: &newline/1,
      displayln: &displayln/1,
      pi: 3.14159265359}
  end
end