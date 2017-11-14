defmodule Klambda.Vector do
  require IEx

  def new(size) do
    # TODO: raise error if size out of bounds
    {:ok, pid} = Agent.start_link( fn -> :array.new(size) end )
    {:array, pid}
  end

  def to_string(_) do
    "<vector ...>"
  end

  def set({:array, pid}, pos, val) do
    Agent.update( pid, fn arr -> :array.set(pos, val, arr) end )
    Agent.get( pid, fn arr -> arr end )
    {:array, pid}
  end

  def get({:array, pid}, pos) do
    Agent.get( pid, fn arr -> :array.get(pos, arr) end )
  end
end
