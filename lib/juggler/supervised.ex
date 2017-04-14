defmodule Juggler.Supervised do
  require Logger

  use GenServer

  def start_link() do
    Logger.info "starting #{__MODULE__}"
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def stop(), do: GenServer.stop(__MODULE__, :stopping)

  def init(_) do
    send(self(), :init)
    {:ok, nil}
  end

  def code_change(_old_vsn, old_pid, _extra) do
    Logger.info "${__MODULE__} code change"
    Process.unlink(old_pid)
    Process.exit(old_pid, :code_change)
    send(self(), :init)
    {:ok, nil}
  end

  def handle_info(:init, nil) do
    pid = spawn_link(Juggler.Simple, :run, [])
    Logger.info "poller pid #{inspect pid}"
    {:noreply, pid}
  end

end
