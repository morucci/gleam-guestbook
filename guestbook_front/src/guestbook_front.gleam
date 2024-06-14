import gleam/dynamic
import gleam/io
import gleam/list
import guestbook_shared/input_message
import guestbook_shared/message
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import lustre_http

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Model {
  Model(
    count: Int,
    cats: List(String),
    messages: List(message.Message),
    input_message: String,
    input_author: String,
  )
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model(0, [], [], "Enter a message", "Your name"), effect.none())
}

pub type Msg {
  UserGetMessages
  UserUpdatedMessage(String)
  UserUpdatedAuthor(String)
  UserSendMessage
  ApiReturnedMessage(Result(message.Message, lustre_http.HttpError))
  ApiReturnedMessages(Result(List(message.Message), lustre_http.HttpError))
  ApiReturnedPostMessage(Result(Nil, lustre_http.HttpError))
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserGetMessages -> #(model, get_messages())
    UserUpdatedMessage(input) -> {
      io.debug(input)
      #(Model(..model, input_message: input), effect.none())
    }
    UserUpdatedAuthor(input) -> {
      io.debug(input)
      #(Model(..model, input_author: input), effect.none())
    }
    UserSendMessage -> {
      #(model, post_message(model.input_message, model.input_author))
    }
    ApiReturnedMessage(Ok(msg)) -> {
      io.debug(msg)
      #(model, effect.none())
    }
    ApiReturnedMessages(Ok(msgs)) -> {
      io.debug(msgs)
      #(Model(..model, messages: msgs), effect.none())
    }
    ApiReturnedPostMessage(Ok(_)) -> {
      io.debug("posted")
      #(model, effect.none())
    }
    ApiReturnedMessage(Error(_)) -> #(model, effect.none())
    ApiReturnedMessages(Error(_)) -> #(model, effect.none())
    ApiReturnedPostMessage(Error(_)) -> #(model, effect.none())
  }
}

fn get_messages() -> effect.Effect(Msg) {
  let decoder = dynamic.list(message.decoder())
  let expect = lustre_http.expect_json(decoder, ApiReturnedMessages)
  lustre_http.get("http://localhost:8000/messages", expect)
}

fn post_message(input_message: String, input_author) -> effect.Effect(Msg) {
  let m = input_message.InputMessage(input_message, input_author)
  lustre_http.post(
    "http://localhost:8000/message",
    input_message.to_json(m),
    lustre_http.expect_anything(ApiReturnedPostMessage),
  )
}

fn messages_h(messages: List(message.Message)) -> element.Element(Msg) {
  let message_h = fn(message: message.Message) -> element.Element(Msg) {
    html.div([], [
      element.text(message.text),
      element.text(" "),
      element.text(message.author),
    ])
  }
  html.div([], list.map(messages, message_h))
}

pub fn view(model: Model) -> element.Element(Msg) {
  html.div([], [
    html.input([
      attribute.value(model.input_message),
      event.on_input(UserUpdatedMessage),
    ]),
    html.input([
      attribute.value(model.input_author),
      event.on_input(UserUpdatedAuthor),
    ]),
    html.button([event.on_click(UserSendMessage)], [element.text("Send")]),
    html.button([event.on_click(UserGetMessages)], [
      element.text("Update messages"),
    ]),
    html.div(
      [],
      list.map(model.cats, fn(cat) {
        html.img([attribute.src("https://cataas.com/cat/" <> cat)])
      }),
    ),
    messages_h(model.messages),
  ])
}
