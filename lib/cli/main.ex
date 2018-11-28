defmodule Chord.Main do
  require Logger

  def main(args) do
    Chord.Protocol.init_chord(
      String.to_integer(Enum.at(args, 0)),
      String.to_integer(Enum.at(args, 1))
    )
  end
end
