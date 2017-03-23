defmodule Juggler.Chats do
  @table :chats

  use GenServer
  require Logger

  def start_link(table_name \\ @table) do
    GenServer.start_link(__MODULE__, table_name, name: __MODULE__)
  end

  def add_chat(chat) do
    GenServer.cast(__MODULE__, {:add_chat, chat})
  end

  def list_chats() do
    GenServer.call(__MODULE__, :list_chats)
  end

  def get_chat(chat_id) do
    GenServer.call(__MODULE__, {:get_chat, chat_id})
  end

  def remove_chat(id) when is_number(id) do
    GenServer.cast(__MODULE__, {:remove_chat, id})
  end

  def remove_chat(chat) do
    remove_chat(chat.id)
  end

  ########## callbacks
  def init(table_name) do
    Logger.debug "Starting #{__MODULE__}"
    {:ok, table} = :dets.open_file(table_name, type: :set)
    {:ok, table}
  end

  def handle_cast({:add_chat, chat}, table) do
    :dets.insert(table, {chat.id, chat})
    {:noreply, table}
  end

  def handle_cast({:remove_chat, chat_id}, table) do
    :dets.delete(table, chat_id)
    {:noreply, table}
  end

  def handle_call(:list_chats, _from, table) do
    chats = :dets.foldl(fn ({_chat_id, chat}, acc) -> [chat | acc] end, [], table)
    {:reply, chats, table}
  end

  def handle_call({:get_chat, chat_id}, _from, table) do
    chat = case :dets.lookup(table, chat_id) do
             [{^chat_id, c}] -> c
             _ -> nil
           end
    {:reply, chat, table}
  end

end
