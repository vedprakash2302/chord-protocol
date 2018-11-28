defmodule Chord.Utils do
  @moduledoc """
  This module defines the utility functions for the project.
  """
  def int_to_atom(n) do
    String.to_atom(Integer.to_string(n))
  end

  def first_enum(list) do
    List.first(Enum.take_random(list, 1))
  end

  def get_pid(n) do
    Process.whereis(int_to_atom(n))
  end

  def timeout do
    150
  end

  def get_task_pid(task) do
    elem(task, 1)
  end

  def getKey() do
    :rand.uniform(trunc(:math.pow(2, Chord.Constant.m())) - 1)
  end

  def belongs(item, node1, node2) do
    cond do
      item == nil or node1 == nil or node2 == nil ->
        false

      node1 < node2 ->
        if item > node1 and item <= node2 do
          true
        else
          false
        end

      node1 >= node2 ->
        if item > node1 or item <= node2 do
          true
        else
          false
        end

      true ->
        false
    end
  end

  def generate_rand_ip_sha(n) do
    Enum.map(1..n, fn _ -> generate_ip_sha() end)
  end

  def generate_ip_sha() do
    m = binary_part(:crypto.hash(:sha, rand_ip()), 20, -2)
    {node_id, _} = Integer.parse(m |> Base.encode16(), Chord.Constant.m())
    node_id
  end

  def rand_ip() do
    Enum.join(
      [:rand.uniform(255), :rand.uniform(255), :rand.uniform(255), :rand.uniform(255)],
      "."
    )
  end
end
