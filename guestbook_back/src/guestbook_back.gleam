import gleam/erlang/process
import gleam/otp/actor
import guestbook_back/router
import guestbook_back/storage
import guestbook_shared/message
import mist
import wisp

pub fn main() {
  // This sets the logger to print INFO level logs, and other sensible defaults
  // for a web application.
  wisp.configure_logger()

  // Here we generate a secret key, but in a real application you would want to
  // load this from somewhere so that it is not regenerated on every restart.
  let secret_key_base = wisp.random_string(64)

  let assert Ok(actor) = actor.start([], storage.handle_message)

  process.send(
    actor,
    storage.Push(message.Message(
      1,
      "This a the first message",
      12_345,
      "Fabien",
    )),
  )
  process.send(
    actor,
    storage.Push(message.Message(
      2,
      "This a the second message",
      12_346,
      "Fabien",
    )),
  )

  let context = router.Context(db: actor)
  let handler = router.handle_request(_, context)

  // Start the Mist web server.
  let assert Ok(_) =
    handler
    |> wisp.mist_handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  // The web server runs in new Erlang process, so put this one to sleep while
  // it works concurrently.
  process.sleep_forever()
}
