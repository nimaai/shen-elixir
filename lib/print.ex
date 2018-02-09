defmodule Klambda.Print do
  alias Klambda.Vector
  require IEx

  def print({:"simple-error", message}) do
    message
  end

  def print({:error, message}) do
    "ERROR: #{message}"
  end

  def print(str) when is_binary(str) do
    "\"" <> str <> "\""
  end

  def print(pid) when is_pid(pid) do
    inspect(pid)
  end

  def print(f) when is_function(f) do
    inspect(f)
  end

  def print([:lambda, id, param, _]) do
    "<lambda (#{param}) #{id}>"
  end

  def print({:cons, [_ | _] = expr}) do
    inspect(expr)
  end

  def print([]) do
    inspect([])
  end

  def print({:array, pid}) do
    Vector.to_string(pid)
  end

  def print(nil) do
    "nil"
  end

  def print(term) do
    to_string term
  end
end
