defmodule Lisp.Env do
  alias Lisp.Bindings
  require IEx

  # def lookup_local(%{locals: locals}, sym) do
  #   locals[sym]
  # end

  def lookup_global(%{globals: pid}, sym) do
    Bindings.lookup(pid, sym)
  end

  # defp lookup_local_helper(%{local: locals, enclosing: enclosing}, sym) do
  #   if val = locals[sym] do
  #     val
  #   else
  #     lookup_local_helper(enclosing, sym)
  #   end
  # end

  # defp lookup_local_helper(locals, sym) do
  #   locals[sym]
  # end

  def lookup_function(%{functions: pid, locals: locals}, sym) do
    gf = Bindings.lookup(pid, sym)
    if is_nil(gf) do
      lf = locals[sym]
      if is_nil(lf) do
        raise "Undefined function #{sym}"
      end
    else
      gf
    end
  end
end
