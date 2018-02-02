defmodule Klambda.Print do
  alias Klambda.Cons
  alias Klambda.Vector

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
    "<native function>"
  end

  def print([:lambda, id, param, _] = lambda) do
    "<lambda (#{param}) #{id}>"
  end

  def print([_ | _] = expr) do
    "<continuation>"
  end

  def print(%Cons{} = cons) do
    Cons.to_string(cons, "[", "]")
  end

  def print({:array, pid}) do
    Vector.to_string(pid)
  end

  def print(:end_of_cons) do
    "[]"
  end

  def print(nil) do
    "nil"
  end

  def print(term) do
    to_string term
  end
end
