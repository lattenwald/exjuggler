defmodule Juggler.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Juggler.Worker.start_link(arg1, arg2, arg3)
      # worker(Juggler.Worker, [arg1, arg2, arg3]),
      worker(Juggler.Chats, []),
      worker(Juggler.Hq, []),
      worker(Juggler.Supervised, [], restart: :permanent)
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Juggler.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
