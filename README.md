# Juggler

Telegram bot to prove Elixir superiority to die-hard Python fan.gps


## Installation & Configuration

```sh
$ mix deps.get
```

Set `token` in `config/config.exs` to your bot token.

## Running supervised application

```sh
$ iex -S mix
```

You can observer supervision tree now

```elixir
iex> :observer.start()
```

## Running simple

```sh
$ iex -S mix
```

```elixir
iex> Application.stop :juggler
iex> pid = Juggler.Simple.spawn_run
```
