import gleam/dynamic
import gleam/int
import gleam/io
import gleam/list
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
  Model(count: Int, cats: List(String))
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model(0, []), effect.none())
}

pub type Msg {
  UserIncrementedCount
  UserDecrementedCount
  UserGetMessage
  UserGetMessages
  ApiReturnedCat(Result(String, lustre_http.HttpError))
  ApiReturnedMessage(Result(message.Message, lustre_http.HttpError))
  ApiReturnedMessages(Result(List(message.Message), lustre_http.HttpError))
}

pub fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    UserIncrementedCount -> #(Model(..model, count: model.count + 1), get_cat())
    UserDecrementedCount -> #(
      Model(..model, count: model.count - 1),
      effect.none(),
    )
    UserGetMessage -> #(model, get_message())
    UserGetMessages -> #(model, get_messages())
    ApiReturnedCat(Ok(cat)) -> #(
      Model(..model, cats: [cat, ..model.cats]),
      effect.none(),
    )
    ApiReturnedCat(Error(_)) -> #(model, effect.none())
    ApiReturnedMessage(Ok(msg)) -> {
      io.debug(msg)
      #(model, effect.none())
    }
    ApiReturnedMessages(Ok(msgs)) -> {
      io.debug(msgs)
      #(model, effect.none())
    }
    ApiReturnedMessage(Error(_)) -> #(model, effect.none())
    ApiReturnedMessages(Error(_)) -> #(model, effect.none())
  }
}

fn get_cat() -> effect.Effect(Msg) {
  let decoder = dynamic.field("_id", dynamic.string)
  let expect = lustre_http.expect_json(decoder, ApiReturnedCat)

  lustre_http.get("https://cataas.com/cat?json=true", expect)
}

fn get_message() -> effect.Effect(Msg) {
  let decoder = message.decoder()
  let expect = lustre_http.expect_json(decoder, ApiReturnedMessage)
  lustre_http.get("http://localhost:8000/message/1", expect)
}

fn get_messages() -> effect.Effect(Msg) {
  let decoder = dynamic.list(message.decoder())
  let expect = lustre_http.expect_json(decoder, ApiReturnedMessages)
  lustre_http.get("http://localhost:8000/messages", expect)
}

pub fn view(model: Model) -> element.Element(Msg) {
  let count = int.to_string(model.count)

  html.div([], [
    html.button([event.on_click(UserIncrementedCount)], [element.text("+")]),
    element.text(count),
    html.button([event.on_click(UserDecrementedCount)], [element.text("-")]),
    html.button([event.on_click(UserGetMessage)], [element.text("get-message")]),
    html.button([event.on_click(UserGetMessages)], [
      element.text("get-messages"),
    ]),
    html.div(
      [],
      list.map(model.cats, fn(cat) {
        html.img([attribute.src("https://cataas.com/cat/" <> cat)])
      }),
    ),
  ])
}
