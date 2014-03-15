defmodule OtpDsl.Mixfile do
  use Mix.Project

  def project do
    [
      app:     :otp_dsl,
      version: "0.0.1",
      elixir:  "> 0.10.3",
      deps:    deps(Mix.env)
    ]
  end

  defp deps(:prod), do: [ ]
  defp deps(_),     do: [ {:meck,  github: "eproxus/meck" } ]

end
