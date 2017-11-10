defmodule Lisp.Vector do
  require IEx

  @enforce_keys [:array]
  defstruct [:array]

  def new(size) do
    # TODO: raise error if size out of bounds
    %Lisp.Vector{array: :array.new(size)}
  end

  def to_string(%Lisp.Vector{}) do
    "<vector ...>"
  end

  def set(%Lisp.Vector{array: arr}, pos, val) do
    # NOTE: it's a destructive update!
    arr = :array.set(pos, val2, arr)
    %Lisp.Vector{array: arr}
  end

  def get(%Lisp.Vector{array: arr}, pos) do
    List.to_atom(:array.get(pos, arr))
  end
end
