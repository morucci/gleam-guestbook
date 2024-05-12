import gleam/dynamic
import gleam/json

pub type Message {
  Message(id: Int, text: String, unix_date: Int, author: String)
}

pub fn to_json(msg: Message) -> json.Json {
  json.object([
    #("id", json.int(msg.id)),
    #("text", json.string(msg.text)),
    #("unix_date", json.int(msg.unix_date)),
    #("author", json.string(msg.author)),
  ])
}

pub fn from_json(json: String) -> Result(Message, json.DecodeError) {
  let decoder =
    dynamic.decode4(
      Message,
      dynamic.field("id", of: dynamic.int),
      dynamic.field("text", of: dynamic.string),
      dynamic.field("unix_date", of: dynamic.int),
      dynamic.field("author", of: dynamic.string),
    )
  json.decode(from: json, using: decoder)
}
