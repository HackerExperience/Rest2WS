# Rest2ws

Rest2WS is a library that allows you to run a REST API that translates the requests to an existing WS-based API.
It makes a few assumptions that we'll try to lax overtime. Currently, it only works with messages that follow the HELF standard.

## Usage

The client side of the REST API depends on the Phoenix framework.

### Step 0 - Install Phoenix

### Step 1 - Configure the WS backend

On your brand new Phoenix installation, add to `config/config.exs`:

```lang=elixir
config :rest2ws,
  route_file: File.cwd! <> "/config/routes.json",
  ws_config: %{
    host: "127.0.0.1",
    port: 8080,
    path: "/ws"
  }
```

### Step 2 - Add your route map

The route map tells how Rest2ws should translate the HTTP requests into WebSocket ones.

Here's an example route map (json):

```lang=json
{
  "/user": {
    "get": {
      "topic": "account.get",
      "args": {}
    },
    "post": }
      "topic": "account.create",
      "args": {
        "user": "uid"
      }
    }
  },
  "/user/:id": {
    "get": {
      "topic": "account.get",
      "args": {
        "id": "uid"
      }
    }
  },
  "/authenticate": {
    "post": {
      "topic": "account.login",
      "args": {}
    }
  }
}
```

The first keys of the route map json represents the REST path. The second one tells which HTTP methods are available. Finally, for each method you specifiy which WebSocket topic the request should be sent to. The `args` key maps the rest arguments (or body arguments) to new variable names. For instance, we specify :id to be the REST argument at /user/:id, but the websocket backend expects an "uid" argument. Rest2ws will make this transformation based on the `args` map.

Save that json on `config/routes.json`.

### Step 3 - Add the routes on Phoenix routes

On `web/router.ex`, add:

```lang=elixir
  scope "/api", MyAPI do
    resources "/user", Rest2WS, only: [:show, :create], param: "user_id"
    resources "/authenticate", Rest2WS, only: [:create]
  end
```

### Step 4 - Add the Rest2WS controller

Create `web/controllers/rest2ws_controller.ex` with the following content:

```lang=elixir
defmodule MyAPI.Rest2WS do
  use Rest2WS.Controller, namespace: MyAPI
end
```

Make sure to change `MyAPI` to your Phoenix project name.

### Step 5 - Run your API

If all is well, simply run `mix phoenix.server` and that should work.

## TODO

- [] Add type specs
- [] Add tests
- [] Translate authentication headers
- [] Translate rate-limit headers
