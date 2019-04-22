defmodule Juggler.Simple do
  require Logger

  import FFmpex
  use FFmpex.Options

  alias Juggler.Hq

  @boss Application.get_env(:juggler, :boss)
  @authorized [@boss | Application.get_env(:juggler, :authorized, [])]
  @bot Application.get_env(:juggler, :bot)

  def spawn_run(), do: spawn(__MODULE__, :run, [])

  def run(offset \\ 0) do
    with {:ok, updates} <- Nadia.get_updates(offset: offset) do
      next_offset =
        case List.last(updates) do
          nil -> offset
          upd -> upd.update_id + 1
        end

      updates |> Enum.map(&process(&1))
      run(next_offset)
    else
      {:error, %Nadia.Model.Error{reason: :timeout}} ->
        Logger.warn("got timeout")
        run(offset)

      other ->
        Logger.error("unknown get_updates error: #{inspect(other)}")
        run(offset)
    end
  end

  def process(%{callback_query: query = %{message: %{chat: chat}}}) do
    react(:callback_query, chat.id, query)
  end

  def process(%{message: message = %{chat: chat}}) do
    Juggler.Chats.add_chat(chat)
    Logger.debug("#{inspect(message)}")
    react(:message, chat.id, message)
  end

  def process(upd) do
    Logger.debug("not processing update: #{inspect(upd)}")
  end

  def react(:message, chat_id, _message = %{message_id: msg_id, text: "/juggle" <> rest})
      when rest in ["", "@#{@bot}"] do
    # fuckoff(chat_id, message)
    spawn(__MODULE__, :juggle, [chat_id, msg_id])
  end

  def react(:message, chat_id, _message = %{message_id: msg_id, text: "/version" <> rest})
      when rest in ["", "@#{@bot}"] do
    Nadia.send_message(
      chat_id,
      Application.spec(:juggler)[:vsn],
      reply_to_message_id: msg_id,
      disable_notification: true
    )
  end

  def react(:message, chat_id, _message = %{message_id: msg_id, text: "/id" <> rest})
      when rest in ["", "@#{@bot}"] do
    Nadia.send_message(
      chat_id,
      "`#{chat_id}`",
      reply_to_message_id: msg_id,
      parse_mode: "Markdown",
      disable_notification: true
    )
  end

  def react(
        :message,
        _chat_id,
        _message = %{
          pinned_message: %{
            chat: %{title: chat_title},
            from: pinned_user,
            message_id: _message_id,
            text: text
          },
          from: pinning_user
        }
      ) do
    format_user = fn
      %{username: username} -> "@#{username}"
      %{firstname: firstname} -> "*#{firstname}*"
    end

    Hq.notify_boss(
      "#{format_user.(pinning_user)} pinned message from #{format_user.(pinned_user)} at *#{
        chat_title
      }*\n\n#{text}"
    )
  end

  def react(
        :message,
        chat_id,
        _message = %{
          message_id: msg_id,
          document: %{
            file_id: file_id,
            file_name: file_name,
            file_size: file_size,
            mime_type: file_type
          },
          forward_from: from,
          chat: chat
        }
      )
      when file_type in ["audio/x-wav", "audio/mpeg", "audio/aac"] do
    from = from || chat
    spawn(__MODULE__, :convert_audio, [chat_id, msg_id, file_id, file_name, from])
  end

  def react(
        :message,
        chat_id,
        message = %{message_id: msg_id, from: %{username: username}, text: text}
      )
      when username in @authorized do
    Hq.command(chat_id, msg_id, text)
    |> case do
      :ok -> :ok
      :no_command -> Hq.forward_to_relevant(chat_id, message)
    end
  end

  def react(:message, chat_id, message = %{chat: %{type: "private", username: username}})
      when not (username in @authorized) do
    Hq.forward_to_relevant(chat_id, message)
  end

  def react(:message, chat_id, message) do
    Hq.forward_to_relevant(chat_id, message) |> inspect |> Logger.debug()
  end

  def react(:callback_query, chat_id, query = %{from: %{username: username}, data: data})
      when username in @authorized do
    Nadia.answer_callback_query(query.id, text: "Так-так-так...")
    Hq.command_callback_query(chat_id, data, query)
  end

  def react(:callback_query, _chat_id, query) do
    Nadia.answer_callback_query(query.id, text: "Я тебя не знаю!")
  end

  def react(_type, _chat_id, upd) do
    Logger.debug("#{inspect(upd)}")
  end

  def fuckoff(chat_id, %{from: %{first_name: fname, username: uname}}) do
    Nadia.send_message(chat_id, "Отвали, #{fname || uname}", disable_notification: true)
  end

  def juggle(chat_id, msg_id) do
    session_id = "J#{Enum.random(1..10000)}"
    Nadia.send_message(chat_id, "ЦЫРК! #{session_id}")

    for thing <- ["левой ногой", "правой рукой", "щупальцами", "тем, что нельзя называть"] do
      :timer.sleep(1000)

      spawn(fn ->
        Nadia.send_message(
          chat_id,
          "Жонглирую #{thing}! #{session_id}\n#{Time.utc_now()}",
          reply_to_message_id: msg_id
        )
      end)
    end
  end

  def convert_audio(chat_id, msg_id, file_id, file_name, from) do
    Logger.info("converting audio file: #{file_name}")

    with {:ok, file} <- Nadia.get_file(file_id),
         {:ok, file_link} <- Nadia.get_file_link(file),
         {:ok, dir} <- Briefly.create(directory: true),
         {:ok, file_path} <- Download.from(file_link, path: Path.join(dir, file_name)),
         detect_command <-
           new_command()
           |> add_input_file(file_path)
           |> add_output_file("/dev/null")
           |> add_stream_specifier(stream_type: :audio)
           |> add_stream_option(option_f("null"))
           |> add_stream_option(option_filter("volumedetect")),
         {cmd, opts} <- prepare(detect_command),
         %{status: 0, out: out} <- Porcelain.exec(cmd, opts, err: :out),
         %{"max_vol" => max_vol} <-
           Regex.named_captures(~r{max_volume: (?<max_vol>[-.\d]+) dB}, out),
         {max_vol, ""} <- Float.parse(max_vol),
         output_file <- Path.rootname(file_path) <> ".mp3",
         norm_vol = -max_vol,
         convert_command <-
           new_command()
           |> add_input_file(file_path)
           |> add_output_file(output_file)
           |> add_stream_specifier(stream_type: :audio)
           |> add_stream_option(option_filter("volume=#{norm_vol}dB"))
           |> add_stream_option(option_codec("libmp3lame"))
           |> add_stream_option(option_qscale("3")),
         :ok <- execute(convert_command) do
      title = Path.basename(file_name, Path.extname(file_name))

      performer =
        case from do
          nil ->
            "Unknown"

          %{first_name: first_name, last_name: last_name, username: username} ->
            [first_name, last_name, map_not_nil(username, &"@#{&1}")]
            |> Enum.filter(&(not is_nil(&1)))
            |> Enum.join(" ")
        end

      Nadia.send_audio(
        chat_id,
        output_file,
        reply_to_message_id: msg_id,
        title: title,
        performer: performer,
        parse_mode: "Markdown"
      )
    else
      other ->
        Nadia.send_message(
          chat_id,
          """
          Что-то пошло не так:
          ```
          #{inspect(other)}
          """,
          reply_to_message_id: msg_id,
          parse_mode: "Markdown"
        )
    end
  end

  ## helpers
  def map_not_nil(nil, fun), do: nil
  def map_not_nil(other, fun), do: fun.(other)
end
