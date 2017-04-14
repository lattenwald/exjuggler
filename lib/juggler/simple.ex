defmodule Juggler.Simple do
  require Logger

  alias Juggler.Hq

  @boss Application.get_env(:juggler, :boss)
  @authorized [@boss | Application.get_env(:juggler, :authorized, [])]
  @bot Application.get_env(:juggler, :bot)

  def spawn_run(), do: spawn(__MODULE__, :run, [])

  def run(offset \\ 0) do
    {:ok, updates} = Nadia.get_updates(offset: offset)

    next_offset =
      case List.last updates do
        nil -> offset
        upd -> upd.update_id + 1
      end

    updates |> Enum.map(&process(&1))

    run(next_offset)
  end

  def process(%{callback_query: query=%{message: %{chat: chat}}}) do
    react(:callback_query, chat.id, query)
  end

  def process(%{message: message=%{chat: chat}}) do
    Juggler.Chats.add_chat(chat)
    Logger.debug "#{inspect message}"
    react(:message, chat.id, message)
  end

  def react(:message, chat_id, _message=%{text: "/juggle" <> rest})
  when rest in ["", "@#{@bot}"] do
    # fuckoff(chat_id, message)
    spawn(__MODULE__, :juggle, [chat_id])
  end

  def react(:message, chat_id, _message=%{text: "/version" <> rest})
  when rest in ["", "@#{@bot}"] do
    Nadia.send_message(chat_id, Application.spec(:qtg)[:vsn], disable_notification: true)
  end

  def react(:message, chat_id, message=%{from: %{username: username}, text: text})
  when username in @authorized do
    Hq.command(chat_id, text)
    |> case do
         :ok -> :ok
         :no_command -> Hq.forward_to_relevant(chat_id, message)
       end
  end

  def react(:message, chat_id, message=%{chat: %{type: "private", username: username}})
  when not username in @authorized do
    Hq.forward_to_relevant(chat_id, message)
  end

  def react(:message, chat_id, message) do
    Hq.forward_to_relevant(chat_id, message) |> inspect |> Logger.debug
  end

  def react(:callback_query, chat_id, query=%{from: %{username: username}, data: data})
  when username in @authorized do
    Nadia.answer_callback_query(query.id, text: "Так-так-так...")
    Hq.command_callback_query(chat_id, data, query)
  end

  def react(:callback_query, _chat_id, query) do
    Nadia.answer_callback_query(query.id, text: "Я тебя не знаю!")
  end

  def react(_type, _chat_id, upd) do
    Logger.debug "#{inspect upd}"
  end

  def fuckoff(chat_id, %{from: %{first_name: fname, username: uname}}) do
    Nadia.send_message(chat_id, "Отвали, #{fname || uname}", disable_notification: true)
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



# 20:48:24.647 [debug] %Nadia.Model.Update{callback_query: nil, chosen_inline_result: nil, edited_message: nil, inline_query: nil, message: %Nadia.Model.Message{audio: nil, caption: nil, channel_chat_created: nil, chat: %Nadia.Model.Chat{first_name: nil, id: -1001115775506, last_name: nil, title: "Aperture Labs Test Facility", type: "supergroup", username: nil}, contact: nil, date: 1489870104, delete_chat_photo: nil, document: nil, edit_date: nil, entities: nil, forward_date: nil, forward_from: nil, forward_from_chat: nil, from: %Nadia.Model.User{first_name: "Alexander", id: 122247178, last_name: nil, username: "lattenwald"}, group_chat_created: nil, left_chat_member: %{first_name: "El Boto", id: 281074394, username: "lattenbot"}, location: nil, message_id: 1039, migrate_from_chat_id: nil, migrate_to_chat_id: nil, new_chat_member: nil, new_chat_photo: [], new_chat_title: nil, photo: [], pinned_message: nil, reply_to_message: nil, sticker: nil, supergroup_chat_created: nil, text: nil, venue: nil, video: nil, voice: nil}, update_id: 546229291}

# 20:48:32.350 [debug] %Nadia.Model.Update{callback_query: nil, chosen_inline_result: nil, edited_message: nil, inline_query: nil, message: %Nadia.Model.Message{audio: nil, caption: nil, channel_chat_created: nil, chat: %Nadia.Model.Chat{first_name: nil, id: -1001115775506, last_name: nil, title: "Aperture Labs Test Facility", type: "supergroup", username: nil}, contact: nil, date: 1489870112, delete_chat_photo: nil, document: nil, edit_date: nil, entities: nil, forward_date: nil, forward_from: nil, forward_from_chat: nil, from: %Nadia.Model.User{first_name: "Alexander", id: 122247178, last_name: nil, username: "lattenwald"}, group_chat_created: nil, left_chat_member: nil, location: nil, message_id: 1040, migrate_from_chat_id: nil, migrate_to_chat_id: nil, new_chat_member: %{first_name: "El Boto", id: 281074394, username: "lattenbot"}, new_chat_photo: [], new_chat_title: nil, photo: [], pinned_message: nil, reply_to_message: nil, sticker: nil, supergroup_chat_created: nil, text: nil, venue: nil, video: nil, voice: nil}, update_id: 546229292}
