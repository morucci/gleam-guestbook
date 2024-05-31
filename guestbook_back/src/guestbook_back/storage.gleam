import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import guestbook_shared/message

pub type Message(e) {
  // The `Shutdown` message is used to tell the actor to stop.
  // It is the simplest message type, it contains no data.
  Shutdown

  // The `Push` message is used to add a new element to the stack.
  // It contains the item to add, the type of which is the `element`
  // parameterised type.
  Push(push: e)

  // The `Pop` message is used to remove an element from the stack.
  // It contains a `Subject`, which is used to send the response back to the
  // message sender. In this case the reply is of type `Result(element, Nil)`.
  Pop(reply_with: Subject(Result(e, Nil)))

  Get(Int, reply_with: Subject(Result(e, Nil)))
}

// The last part is to implement the `handle_message` callback function.
//
// This function is called by the Actor each for each message it receives.
// Actor is single threaded only does one thing at a time, so it handles
// messages sequentially and one at a time, in the order they are received.
//
// The function takes the message and the current state, and returns a data
// structure that indicates what to do next, along with the new state.
pub fn handle_message(
  message: Message(message.Message),
  stack: List(message.Message),
) -> actor.Next(Message(message.Message), List(message.Message)) {
  case message {
    // For the `Shutdown` message we return the `actor.Stop` value, which causes
    // the actor to discard any remaining messages and stop.
    Shutdown -> actor.Stop(process.Normal)

    // For the `Push` message we add the new element to the stack and return
    // `actor.continue` with this new stack, causing the actor to process any
    // queued messages or wait for more.
    Push(value) -> {
      let new_state = [value, ..stack]
      actor.continue(new_state)
    }

    // For the `Pop` message we attempt to remove an element from the stack,
    // sending it or an error back to the caller, before continuing.
    Pop(client) ->
      case stack {
        [] -> {
          // When the stack is empty we can't pop an element, so we send an
          // error back.
          process.send(client, Error(Nil))
          actor.continue([])
        }

        [first, ..rest] -> {
          // Otherwise we send the first element back and use the remaining
          // elements as the new state.
          process.send(client, Ok(first))
          actor.continue(rest)
        }
      }
    Get(id, client) -> {
      case stack {
        [] -> process.send(client, Error(Nil))
        _ -> {
          case
            list.filter(stack, fn(m: message.Message) { m.id == id })
            |> list.first
          {
            Ok(m) -> process.send(client, Ok(m))
            Error(_) -> process.send(client, Error(Nil))
          }
        }
      }
      actor.continue(stack)
    }
  }
}
