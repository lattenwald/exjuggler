defmodule Juggler.Simple do
  require Logger

  def spawn_run(), do: spawn(__MODULE__, :run, [])

  def run(offset \\ 0) do
    {:ok, updates} = Nadia.get_updates(offset: offset)

    next_offset =
      case List.last updates do
        nil -> offset
        upd -> upd.update_id + 1
      end

    if offset > 0, do: Enum.map(updates, &process(&1))

    run(next_offset)
  end

  def process(upd=%{message: %{text: "/juggle" <> _, chat: %{id: chat_id}}}) do
    Logger.debug "#{inspect upd}"
    spawn(__MODULE__, :juggle, [chat_id])
  end

  def process(upd) do
    Logger.debug "#{inspect upd}"
  end

  def juggle(chat_id) do
    session_id = "J#{Enum.random 1..10000}"
    Nadia.send_message(chat_id, "ЦЫРК! #{session_id}")
    for thing <- ["левой ногой", "правой рукой", "щупальцами", "тем, что нельзя называть"] do
      :timer.sleep(1000)
      spawn fn -> Nadia.send_message(chat_id, "Жонглирую #{thing}! #{session_id}\n#{Time.utc_now()}") end
    end
  end
end
