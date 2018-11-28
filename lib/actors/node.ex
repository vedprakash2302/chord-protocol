defmodule Chord.Node do
  use GenServer
  require Logger

  @moduledoc """
  This module defines the individual nodes and behaviour in the network.
  """

  @doc """
  Starts the Genserver.
  """
  def start_link(node, index, finger_table, predecessor) do
    GenServer.start_link(__MODULE__, [node, index, finger_table, predecessor],
      name: Chord.Utils.int_to_atom(node)
    )
  end

  @doc """
  Initializes the Genserver.
  """
  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Handler to create the Chord ring and initialize the finger table.
  """
  @impl true
  def handle_call(:create, _from, [node, index, finger_table, _]) do
    predecessor = nil
    finger_table = Map.put(finger_table, 1, node)
    new_state = [node, index, finger_table, predecessor]
    stabilize()
    fix_fingers(1)
    {:reply, :ok, new_state}
  end

  @doc """
  Handler to handle the calls to join a node to the chord ring.
  """
  @impl true
  def handle_call({:join, known_node}, _from, [node, index, finger_table, _]) do
    predecessor = nil
    IO.puts("Node joined ##{index} #{node}")
    successor = GenServer.call(Chord.Utils.get_pid(known_node), {:find_successor, node})
    finger_table = Map.put(finger_table, 1, successor)

    new_state = [node, index, finger_table, predecessor]

    stabilize()
    fix_fingers(1)
    {:reply, :ok, new_state}
  end

  @doc """
  Handler to print the state of the Genserver.
  """
  @impl true
  def handle_call(:print, _from, state) do
    IO.inspect(state)
    {:reply, :ok, state}
  end

  @doc """
  Handler to find the Successor of the given identifier.
  """
  @impl true
  def handle_call({:find_successor, search_id}, _from, [node, index, finger_table, predecessor]) do
    state = [node, index, finger_table, predecessor]

    if Chord.Utils.belongs(search_id, node, finger_table[1]) do
      {:reply, finger_table[1], state}
    else
      node_closest = closest_preceding_node(node, search_id, finger_table)

      if node_closest == node do
        {:reply, node, state}
      else
        try do
          value = GenServer.call(Chord.Utils.get_pid(node_closest), {:find_successor, search_id})
          {:reply, value, state}
        catch
          :exit, _ ->
            {:reply, node, state}
        end
      end
    end
  end

  @doc """

  Handler to return the node's predecessor.
  """
  @impl true
  def handle_call(:predecessor, _from, [node, index, finger_table, predecessor]) do
    state = [node, index, finger_table, predecessor]
    {:reply, predecessor, state}
  end

  @doc """
  Handler to determine the identifier for the node which mapos to a given key.
  """
  @impl true
  def handle_call({:search_key, hop, key}, _from, [node, index, finger_table, predecessor]) do
    state = [node, index, finger_table, predecessor]
    value = check_successor(key, hop, [node, finger_table, predecessor])
    {:reply, value, state}
  end

  @doc """
  Handler to search for the successor of a given key.
  """
  @impl true
  def handle_call({:search_successor, hop, search_id}, _from, [
        node,
        index,
        finger_table,
        predecessor
      ]) do
    state = [node, index, finger_table, predecessor]

    if predecessor != nil and Chord.Utils.belongs(search_id, predecessor, node) do
      {:reply, {node, hop}, state}
    else
      if Chord.Utils.belongs(search_id, node, finger_table[1]) do
        hop = hop + 1
        {:reply, {finger_table[1], hop}, state}
      else
        node_closest = closest_preceding_node(node, search_id, finger_table)

        if node_closest == node do
          {:reply, {node, hop}, state}
        else
          try do
            value =
              GenServer.call(
                Chord.Utils.get_pid(node_closest),
                {:search_successor, hop + 1, search_id}
              )

            {:reply, {value, hop}, state}
          catch
            :exit, _ ->
              {:reply, {node, hop}, state}
          end
        end
      end
    end
  end

  @doc """
  Procedure to find the successor of a given key.
  """
  def check_successor(search_id, hop, [node, finger_table, predecessor]) do
    if predecessor != nil and Chord.Utils.belongs(search_id, predecessor, node) do
      {node, hop}
    else
      if Chord.Utils.belongs(search_id, node, finger_table[1]) do
        {finger_table[1], hop + 1}
      else
        node_closest = closest_preceding_node(node, search_id, finger_table)

        if node_closest == node do
          {node, hop}
        else
          GenServer.call(
            Chord.Utils.get_pid(node_closest),
            {:search_successor, hop + 1, search_id}
          )
        end
      end
    end
  end

  @doc """
  Procedure to find the closest preceeding node for a given key.
  """
  def closest_preceding_node(node, id, finger_table) do
    temp =
      Enum.filter(Chord.Constant.m()..1, fn x ->
        Chord.Utils.belongs(finger_table[x], node, id)
      end)

    if temp != [] do
      finger_table[List.first(temp)]
    else
      node
    end
  end

  @doc """
  Handler to notify the successor of the joining node to change its predeceddor to the calling node.
  """
  @impl true
  def handle_cast({:notify, calling_node}, [node, index, finger_table, predecessor]) do
    state = [node, index, finger_table, predecessor]

    if predecessor == nil or Chord.Utils.belongs(calling_node, predecessor, node) do
      predecessor = calling_node
      new_state = [node, index, finger_table, predecessor]
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @doc """
  Procedure to periodically call the stabilize routine for the node.
  """
  def stabilize() do
    Process.send_after(self(), :stabilize, 1000)
  end

  @doc """
  Handler to fix the successor of the node preceeding the node that just joined the ring.
  """
  def handle_info(:stabilize, [node, index, finger_table, predecessor]) do
    state = [node, index, finger_table, predecessor]
    x = get_predecessor(node, finger_table[1], predecessor)

    if Chord.Utils.belongs(x, node, finger_table[1]) do
      successor = x
      finger_table = Map.put(finger_table, 1, successor)
      GenServer.cast(Chord.Utils.get_pid(successor), {:notify, node})
      stabilize()
      {:noreply, [node, index, finger_table, predecessor]}
    else
      GenServer.cast(Chord.Utils.get_pid(finger_table[1]), {:notify, node})
      stabilize()
      {:noreply, state}
    end
  end

  @doc """
  Handler to fix the fingr table for each node.
  """
  @impl true
  def handle_info({:fix_fingers, next}, [node, index, finger_table, predecessor]) do
    position = rem(node + trunc(:math.pow(2, next - 1)), trunc(:math.pow(2, Chord.Constant.m())))
    next_node = find_successor(position, [node, finger_table])
    finger_table = Map.put(finger_table, next, next_node)
    next = next + 1

    if next > Chord.Constant.m() do
      fix_fingers(1)
    else
      fix_fingers(next)
    end

    {:noreply, [node, index, finger_table, predecessor]}
  end

  def check_table(key, node, predecessor) do
    if(Chord.Utils.belongs(key, predecessor, node)) do
      true
    else
      false
    end
  end

  @doc """
  Procedure to get the predecessor for a given node.
  """
  def get_predecessor(node, successor, predecessor) do
    if successor == node do
      predecessor
    else
      [_, _, _, predecessor] = :sys.get_state(Chord.Utils.get_pid(successor))
      predecessor
    end
  end

  @doc """
  Procedure to find the successor for a given key identifier.
  """
  def find_successor(search_id, [node, finger_table]) do
    if Chord.Utils.belongs(search_id, node, finger_table[1]) do
      finger_table[1]
    else
      node_closest = closest_preceding_node(node, search_id, finger_table)

      if node_closest == node do
        node
      else
        try do
          value = GenServer.call(Chord.Utils.get_pid(node_closest), {:find_successor, search_id})
          value
        catch
          :exit, _ -> node
        end
      end
    end
  end

  @doc """
  Procedure to run the fix fingers handler continuously.
  """
  def fix_fingers(next) do
    Process.send_after(self(), {:fix_fingers, next}, 400)
  end
end
