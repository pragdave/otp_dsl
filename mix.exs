defmodule OtpDsl.Mixfile do
  use Mix.Project

  def project do
    [ app: :otp_dsl,
      version: "0.0.1",
      elixir: "~> 0.10.2-dev",
      deps: deps ]
  end

  defp application, do: []
  defp deps,        do: []

end
