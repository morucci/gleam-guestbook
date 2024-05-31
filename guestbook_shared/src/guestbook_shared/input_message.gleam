import gleam/dynamic

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
