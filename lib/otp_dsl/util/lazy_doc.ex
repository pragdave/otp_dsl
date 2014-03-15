defmodule OtpDsl.Util.LazyDoc do

  @moduledoc """
  Extract  documentation from a project's README.md file
  """

  @readme File.read!(__DIR__ <> "/../../../README.md") |> String.split(~r{^\#\# }m) |> Enum.map(&("## " <> &1))

  def for(start_line) do
    Enum.find(@readme, "missing documentation\n", &(String.starts_with?(&1, start_line)))
  end

end
