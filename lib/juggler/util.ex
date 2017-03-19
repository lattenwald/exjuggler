defmodule Juggler.Util do
  def chat_title(%{type: "private", username: uname}), do: "@#{uname}"
  def chat_title(%{title: title}), do: title
end
