import birl
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
  #(Model(0, [], [], "", ""), get_messages())
}

pub type Msg {
  UserUpdatedMessage(String)
  UserUpdatedAuthor(String)
  UserSendMessage
  ApiReturnedMessages(Result(List(message.Message), lustre_http.HttpError))
  ApiReturnedPostMessage(Result(Nil, lustre_http.HttpError))
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
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
    ApiReturnedMessages(Ok(msgs)) -> {
      io.debug(msgs)
      #(Model(..model, messages: msgs), effect.none())
    }
    ApiReturnedPostMessage(Ok(_)) -> {
      io.debug("posted")
      #(model, get_messages())
    }
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

fn messages_view(messages: List(message.Message)) -> element.Element(Msg) {
  let message_h = fn(message: message.Message) -> element.Element(Msg) {
    html.div([attribute.class("flex m-1")], [
      html.div([attribute.class("w-1/3 px-2")], [
        element.text(message.unix_date |> birl.from_unix |> birl.to_naive),
      ]),
      html.div([attribute.class("w-1/3 px-2")], [element.text(message.text)]),
      html.div([attribute.class("w-1/3 px-2")], [element.text(message.author)]),
    ])
  }
  html.div([], list.map(messages, message_h))
}

pub fn view(model: Model) -> element.Element(Msg) {
  html.div([attribute.class("flex flex-col")], [
    html.div([attribute.class("flex")], [
      html.div([attribute.class("w-1/3 px-2")], [
        html.input([
          attribute.class(
            "shadow appearance-none border rounded py-2 px-3 text-gray-700",
          ),
          attribute.value(model.input_message),
          attribute.placeholder("Your message"),
          event.on_input(UserUpdatedMessage),
        ]),
      ]),
      html.div([attribute.class("w-1/3 px-2")], [
        html.input([
          attribute.class(
            "shadow appearance-none border rounded py-2 px-3 text-gray-700",
          ),
          attribute.value(model.input_author),
          attribute.placeholder("Your Name"),
          event.on_input(UserUpdatedAuthor),
        ]),
      ]),
      html.div([attribute.class("w-1/3 px-2")], [
        html.button(
          [
            attribute.type_("button"),
            attribute.class(
              "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded",
            ),
            event.on_click(UserSendMessage),
          ],
          [element.text("Send")],
        ),
      ]),
    ]),
    html.div([], [messages_view(model.messages)]),
  ])
}
