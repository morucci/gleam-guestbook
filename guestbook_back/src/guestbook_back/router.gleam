import birl
import gleam/int
import gleam/json
import guestbook_back/web
import guestbook_shared/message
import lustre/element.{text, to_string_builder}
import lustre/element/html.{div, p}
import wisp.{type Request, type Response}

pub type Person {
  Person(name: String, age: Int)
}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["person"] -> person(req)
    ["message", mid_s] ->
      case int.base_parse(mid_s, 2) {
        Ok(parsed) -> get_message(parsed)
        Error(_) -> wisp.bad_request()
      }

    [] -> home_page(req)
    _ -> wisp.not_found()
  }
}

pub fn get_message(_mid: Int) -> Response {
  let message =
    message.Message(
      1,
      "Test message",
      birl.now()
        |> birl.to_unix,
      "Fabien",
    )
  wisp.json_response(json.to_string_builder(message.to_json(message)), 200)
}

pub fn home_page(_req: Request) -> Response {
  let body = div([], [p([], [text("Hello Joe 2")])])
  wisp.html_response(to_string_builder(body), 200)
}

pub fn person(_req: Request) -> Response {
  let person = Person("Fabien", 12)
  let object =
    json.object([
      #("name", json.string(person.name)),
      #("age", json.int(person.age)),
    ])
  wisp.json_response(json.to_string_builder(object), 200)
}
