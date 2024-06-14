import gleam/dynamic
import gleam/json

pub type InputMessage {
  InputMessage(text: String, author: String)
}

pub fn decoder() -> fn(dynamic.Dynamic) ->
  Result(InputMessage, List(dynamic.DecodeError)) {
  dynamic.decode2(
    InputMessage,
    dynamic.field("text", of: dynamic.string),
    dynamic.field("author", of: dynamic.string),
  )
}

pub fn to_json(msg: InputMessage) -> json.Json {
  json.object([
    #("text", json.string(msg.text)),
    #("author", json.string(msg.author)),
  ])
}
