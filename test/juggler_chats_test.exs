Application.put_env(:juggler, :boss, "bossuname")

defmodule JugglerChatsTest do
  use ExUnit.Case
  doctest Juggler.Chats

  test "code loaded" do
    assert Code.ensure_loaded?(Juggler.Chats)
  end

  test "initial state is empty" do
    assert Juggler.Chats.list_chats() == []
  end

  test "adding and removing chat" do
    chat = %{
      id: 1, type: "private", username: "testuname",
      first_name: "test fname", last_name: "test lname"
    }

    assert Juggler.Chats.add_chat(chat) == :ok
    assert Juggler.Chats.list_chats == [chat]
    assert Juggler.Chats.get_chat(1) == chat
    assert Juggler.Chats.get_chat(2) == nil

    assert Juggler.Chats.remove_chat(chat) == :ok
    assert Juggler.Chats.list_chats == []
    assert Juggler.Chats.get_chat(1) == nil

    assert Juggler.Chats.add_chat(chat) == :ok
    assert Juggler.Chats.list_chats == [chat]

    assert Juggler.Chats.remove_chat(1) == :ok
    assert Juggler.Chats.list_chats == []
    assert Juggler.Chats.get_chat(1) == nil
  end

end
