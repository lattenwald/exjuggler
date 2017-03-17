defmodule Juggler.Supervised do
  require Logger

  use GenServer

  def start_link() do
    Logger.info "starting #{__MODULE__}"
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def stop(), do: GenServer.stop(__MODULE__, :stopping)

  def init(_) do
    pid = spawn_link(Juggler.Simple, :run, [])
    Logger.info "poller pid #{inspect pid}"
    {:ok, pid}
  end

end
