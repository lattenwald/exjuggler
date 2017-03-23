defmodule Juggler.Chats do
  @boss Application.get_env(:juggler, :boss)

  def start_link() do
    initial_state = %{}
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def add_chat(chat) do
    Agent.update(__MODULE__, &Map.put(&1, chat.id, chat))
  end

  def list_chats(), do: Agent.get(__MODULE__, &Map.values(&1))

  def get_chat(chat_id) do
    Agent.get(__MODULE__, &Map.get(&1, chat_id))
  end

  def remove_chat(id) when is_number(id) do
    Agent.update(__MODULE__, &Map.delete(&1, id))
  end

  def remove_chat(chat) do
    Agent.update(__MODULE__, &Map.delete(&1, chat.id))
  end

  def boss_chat() do
    Agent.get(
      __MODULE__,
      fn s ->
        s
        |> Map.values
        |> Enum.filter(fn
          %{type: "private", username: @boss} -> true
          _ -> false
        end)
        |> List.first
      end)
  end

end
