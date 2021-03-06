defmodule Juggler.Mixfile do
  use Mix.Project

  def project do
    [app: :juggler,
     version: "0.2.1",
     elixir: "~> 1.7",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      extra_applications: [:logger, :edeliver, :runtime_tools],
      mod: {Juggler.Application, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:nadia, git: "https://github.com/lattenwald/nadia.git"},
      {:distillery, "~> 2.0"},
      {:edeliver, "~> 1.6"},
      {:briefly, "~> 0.3.0"},
      {:download, "~> 0.0.4"},
      {:ffmpex, git: "https://github.com/lattenwald/ffmpex.git"},
      {:porcelain, "~> 2.0"},
      {:httpoison, "~> 1.5"},
      {:poison, "~> 4.0"}
      # {:edeliver, github: "lattenwald/edeliver"},
    ]
  end
end
