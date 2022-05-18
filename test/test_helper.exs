Application.put_env(:searchable_select, SearchableSelect.Endpoint,
  url: [host: "localhost", port: 4000],
  secret_key_base: "MInJnJwPGd4s6XbOHSh1fR13Ns710eCIj+NZ2f+vPAln6HtqK/+0UNBL4BcCGxSw",
  live_view: [signing_salt: "abcdefgh"],
  check_origin: false
)

defmodule SearchableSelect.Endpoint do
  use Phoenix.Endpoint, otp_app: :searchable_select

  plug(Plug.Session,
    store: :cookie,
    key: "_searchable_select_key",
    signing_salt: "abcdefgh"
  )
end

Supervisor.start_link([SearchableSelect.Endpoint], strategy: :one_for_one)

ExUnit.start()
