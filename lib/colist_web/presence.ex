defmodule ColistWeb.Presence do
  use Phoenix.Presence,
    otp_app: :colist,
    pubsub_server: Colist.PubSub
end
