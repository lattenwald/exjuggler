defmodule Juggler.Hq do
  defstruct msg_chat: nil

  alias Juggler.Util

  require Logger
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def command(chat_id, "/msg") do
    buttons =
      Juggler.Chats.list_chats
      |> Enum.map(fn {_, c} -> [%Nadia.Model.InlineKeyboardButton{text: Util.chat_title(c), callback_data: "msg #{c.id}", url: ""}] end)

    Nadia.send_message(chat_id, "Куда?", reply_markup: %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: buttons})
  end

  def command(chat_id, "/cancel") do
    GenServer.call(__MODULE__, :cancel)
    Nadia.send_message(chat_id, "Что-то отменили")
  end

  def command(chat_id, command) do
    GenServer.call(__MODULE__, {:other_command, chat_id, command})
  end

  def command_callback_query(chat_id, "msg " <> other_chat, query) do
    other_chat = other_chat |> String.to_integer
    message_to_chat(chat_id, query.message.message_id, other_chat)
  end

  def command_callback_query(_chat_id, data, _query) do
    Logger.debug "unsupported callback query: #{data}"
  end

  def message_to_chat(chat_id, message_id, other_chat) do
    chat = Juggler.Chats.get_chat(other_chat)
    Logger.debug "#{inspect chat}"
    if chat == nil do
      Nadia.edit_message_text(chat_id, message_id, nil, "Нет такого чата")
    else
      GenServer.call(__MODULE__, {:message_to, other_chat})
      Nadia.edit_message_text(chat_id, message_id, nil, "Введите сообщение для *#{Util.chat_title(chat)}*", parse_mode: "Markdown")
    end
  end

  ############# callbacks
  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def handle_call({:message_to, other_chat}, _from, state) do
    {:reply, :ok, %{state | msg_chat: other_chat}}
  end

  def handle_call({:other_command, _chat_id, _command}, _from, state=%{msg_chat: nil}) do
    # Logger.debug "Unsupported command: #{command}"
    {:reply, :ok, state}
  end

  def handle_call({:other_command, chat_id, command}, _from, state=%{msg_chat: other_chat}) do
    Nadia.send_message(other_chat, command)
    Nadia.send_message(chat_id, "Отправлено!")
    {:reply, :ok, %{state | msg_chat: nil}}
  end

  def handle_call(:cancel, _from, _state) do
    {:reply, :ok, %__MODULE__{}}
  end

end
