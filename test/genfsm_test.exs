defmodule OtpDsl.GemfsmTest do
  use ExUnit.Case

  require OtpDsl.Genfsm

  defmodule Fsm do
    use OtpDsl.Genfsm, register: {:local, :test_fsm},
                       initial_state: :start,
                       init_params: [:p1, :p2]

    events do
      arity0
      arity2(a,b)
    end

    in_state :state0 do
      { :arity0 } ->  next_state(:state1, context)
      { :arity2, a, b } -> next_state(:state1, context ++ [a, b])
    end
  end

  setup_all do
    :meck.new(:gen_fsm, [:unstick])
    :ok
  end


  test "the name gets set" do
    assert Fsm.my_name == :test_fsm
  end

  test "the events generate appropriate functions" do
    fns = Fsm.__info__(:functions)
    assert fns[:arity0] == 0
    assert fns[:arity2] == 2
  end

  test "calling the event invokes GemFSM" do
    :meck.expect(:gen_fsm, :send_event, fn(a,b) -> { :mocked, a, b} end)
    assert Fsm.arity0() == { :mocked, :test_fsm, :arity0 }
  end

  test "calling the event invokes GemFSM with parameters" do
    :meck.expect(:gen_fsm, :send_event, fn(a,b) -> { :mocked, a, b} end)
    assert Fsm.arity2(2,3) == { :mocked, :test_fsm, {:arity2, 2, 3} }
  end


  test "the states generate appropriate functions" do
    fns = Fsm.__info__(:functions)
    assert fns[:state0] == 2
  end

  test "invoking a state returns the appropriate next state" do
    assert Fsm.state0({:arity2, 88, 99}, [:context]) == {:next_state, :state1, [:context, 88, 99]}
  end

  test "next_state returns the correct info" do
    assert OtpDsl.Genfsm.next_state(:state1, [1,2]) == {:next_state, :state1, [1,2] }
  end

  test "next_state returns the correct info with timeout" do
    assert OtpDsl.Genfsm.next_state(:state1, [1,2], 1234) == {:next_state, :state1, [1,2], 1234 }
  end


end
