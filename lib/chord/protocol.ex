defmodule Chord.Protocol do
  require Logger

  @moduledoc """
  This module defines the network creation for Chord protocol.
  """

  @doc """
  Procedure to set off network creation given a size for the network.
  """
  def init_chord(n, request_size) do
    node_list = Chord.Utils.generate_rand_ip_sha(n)
    create_network(n, node_list)
    keys_init(node_list, request_size)
  end

  @doc """
  Procedure to create the chord ring given a node list.
  """
  def create_network(n, node_list) do
    first_node = Enum.at(node_list, 0)
    Chord.Node.start_link(first_node, 1, %{}, nil)
    GenServer.call(Chord.Utils.get_pid(first_node), :create)
    IO.puts("Chord network created with node #1 #{first_node}")

    if n > 1 do
      for i <- 2..n do
        Process.sleep(100)
        node = Enum.at(node_list, i - 1)
        Chord.Node.start_link(node, i, %{}, nil)
        GenServer.call(Process.whereis(Chord.Utils.int_to_atom(node)), {:join, first_node})
      end
    end
  end

  @doc """
  Procedure to count the average hops made per request in the network.
  """
  def keys_init(node_list, request_size) do
    IO.puts("Looking up keys")
    Process.sleep(1000)

    res =
      node_list
      |> Stream.map(&Task.async(Chord.Protocol, :search_keys, [&1, request_size, 0]))
      |> Enum.map(&Task.await(&1, :infinity))

    avg_hop_count = Enum.sum(res) / (Enum.count(res) * request_size)
    IO.puts("Average hop count is #{avg_hop_count}")
  end

  @doc """
  Proceure to find the node which maps to a key given the key identifier.
  """
  def search_keys(node, request_size, sum) do
    Process.sleep(100)

    if request_size == 0 do
      sum
    else
      key = Chord.Utils.getKey()
      {_, val} = GenServer.call(Chord.Utils.get_pid(node), {:search_key, 0, key})
      IO.puts("Found key #{key} in #{val} hops by node #{node}")
      sum = sum + val
      search_keys(node, request_size - 1, sum)
    end
  end
end
