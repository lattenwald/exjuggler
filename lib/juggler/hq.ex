defmodule Juggler.Hq do
  @bot Application.get_env(:juggler, :bot)

  alias Juggler.Util

  require Logger
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def command(chat_id, "/msg" <> rest)
  when rest in ["", "@#{@bot}"] do
    case Juggler.Chats.list_chats do
      [] ->
        Nadia.send_message(chat_id, "Некуда слать-то.")

      chats ->
        prepare_message_to_chat(chat_id)

        buttons =
          chats
          |> Enum.map(fn {_, c} -> [%Nadia.Model.InlineKeyboardButton{text: Util.chat_title(c), callback_data: "msg #{c.id}", url: ""}] end)

        Nadia.send_message(chat_id, "Куда?", reply_markup: %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: buttons})
    end
  end

  def command(chat_id, "/cancel" <> rest)
  when rest in ["", "@#{@bot}"] do
    case GenServer.call(__MODULE__, {:cancel, chat_id}) do
      :none -> :ok
      nil   -> Nadia.send_message(chat_id, "Выбор чата отменён")
      other ->
        chat = Juggler.Chats.get_chat(other)
        Nadia.send_message(chat_id, "Закончили писать в *#{Util.chat_title(chat)}*", parse_mode: "Markdown")
    end
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
      case GenServer.call(__MODULE__, {:message_to, chat_id, other_chat}) do
        :ok ->
          Nadia.edit_message_text(chat_id, message_id, nil, "Введите сообщение для *#{Util.chat_title(chat)}*", parse_mode: "Markdown")

        :error ->
          Nadia.edit_message_text(chat_id, message_id, nil, "Похоже, это предложение устарело")
      end
    end
  end

  def prepare_message_to_chat(chat_id) do
    GenServer.call(__MODULE__, {:prepare_message_to, chat_id})
  end

  ############# callbacks
  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:message_to, chat_id, other_chat}, _from, state) do
    case Map.fetch(state, chat_id) do
      {:ok, _} ->
        {:reply, :ok, Map.put(state, chat_id, other_chat)}

      :error ->
        {:reply, :ready, state}
    end
  end

  def handle_call({:prepare_message_to, chat_id}, _from, state) do
    {:reply, :ok, Map.put(state, chat_id, nil)}
  end

  def handle_call({:other_command, chat_id, command}, _from, state) do
    case Map.fetch(state, chat_id) do
      :error ->
        # Logger.debug "Unsupported command: #{command}"
        {:reply, :ok, state}

      {:ok, nil} ->
        Nadia.send_message(chat_id, "Кому-кому?")
        {:reply, :ok, state}

      {:ok, other_chat} ->
        Nadia.send_message(other_chat, command)
        Nadia.send_message(chat_id, "Отправлено! Ещё что-нибудь?")
        {:reply, :ok, state}
    end
  end

  def handle_call({:cancel, chat_id}, _from, state) do
    {val, new_state} = Map.pop(state, chat_id, :none)
    {:reply, val, new_state}
  end

end
