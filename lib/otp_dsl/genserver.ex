defmodule OtpDsl.Genserver do

  defmodule ReplyUser do
    @moduledoc false
    defmacro reply(value) do
      quote do: { :reply, unquote(value), var!(state, :user) }
    end
  end

  defmodule ReplyNil do
    @moduledoc false
    defmacro reply(value) do
      quote do: { :reply, unquote(value), var!(state) }
    end
  end

  @moduledoc OtpDsl.Util.LazyDoc.for("## OtpDsl.Genserver")



  @doc nil
  defmacro __using__(options) do
    register      = Keyword.get(options, :register,      nil)
    initial_state = Keyword.get(options, :initial_state, nil)
#    tracing       = Keyword.get(options, :trace,         false)

    quote do
      use GenServer.Behaviour
      import unquote(__MODULE__)

      if unquote(register) do
        def my_name do
          elem(unquote(register), 1)
        end

        def start_link() do
          :gen_server.start_link(unquote(register), __MODULE__, unquote(initial_state), [])
        end
      else
        def my_name do
          name_from(__MODULE__)
        end
        def start_link() do
          :gen_server.start_link({:local, my_name}, __MODULE__, unquote(initial_state), [])
        end
      end

    end
  end

  @doc """
  Define both a module API and the function that handles calls to that API in the server.
  For example, if you write

      defcall increment(n) do
        reply(n+1)
      end

  You will get the following two functions defined

     def increment(n) do
       gen_server.call(my_name, {:increment, n})
     end

     def handle_call({:increment, n}, _from, state) do
       { :reply, n+1, state }
     end
  """

  defmacro defcall({name, meta, params}=defn, do: body) do
    # See if the user has provided the `state` argument
    varctx = if Enum.find(params, fn {pname, _, _} -> pname == :state end) do
      # Remove it from function signatures
      params = List.keydelete params, :state, 0
      defn = {name,meta,params}
      nil
    else
      :user
    end

    quote do
      def unquote(defn) do
        :gen_server.call(my_name, {unquote(name), unquote_splicing(params)})
      end

      def handle_call({unquote(name), unquote_splicing(params)}, var!(_from, nil), var!(state, unquote(varctx))) do
        # This is a workaround to keep the compiler at bay
        unquote(if varctx == :user do
          quote do: import(ReplyUser, only: [reply: 1])
        else
          quote do: import(ReplyNil, only: [reply: 1])
        end)

        unquote(body)
      end
    end
  end

  #@doc """
  #Generate a reply from a call handler that does not change the state.  The value will be
  #returned as the second element of the :reply tuple.
  #"""
  #def reply(value)

  @doc """
  Generate a reply from a call handler and also set the state.  The value will be
  returned as the second element of the :reply tuple, and the new state as the third.
  """
  defmacro reply_with_state(args, new_state) do
    quote do
      { :reply, unquote(args), unquote(new_state) }
    end
  end

  #####
  # Ideally should be private, but...

  def name_from(module_name) do
    Regex.replace(%r{(.)\.?([A-Z])}, inspect(module_name), "\\1_\\2")
    |> String.downcase
    |> binary_to_atom
  end
end
