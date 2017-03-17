# Juggler

Telegram bot to prove Elixir superiority to die-hard Python fan.

## Installation & Configuration

```sh
$ mix deps.get
```

Set `token` in `config/config.exs` to your bot token.

## Running simple

```sh
$ iex -S mix
```

```
iex> pid = Juggler.Simple.spawn_run()
```
