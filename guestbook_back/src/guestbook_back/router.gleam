import birl
import gleam/erlang/process.{type Subject}
import gleam/http
import gleam/io
import gleam/json
import guestbook_back/storage
import guestbook_back/web
import guestbook_shared/input_message
import guestbook_shared/message
import lustre/element.{text, to_string_builder}
import lustre/element/html.{div, p}
import wisp.{type Request, type Response}

pub type Context {
  Context(db: Subject(storage.Message(message.Message)))
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["message", id] ->
      case req.method {
        http.Get -> get_message(id, ctx)
        _ -> wisp.bad_request()
      }
    ["message"] ->
      case req.method {
        http.Post -> post_message(req, ctx)
        _ -> wisp.bad_request()
      }
    [] -> home_page(req)
    _ -> wisp.not_found()
  }
}

pub fn post_message(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_json(req)
  let decoder = input_message.decoder()
  case decoder(json) {
    Ok(im) -> {
      let id = wisp.random_string(64)
      let date = birl.to_unix(birl.now())
      let m = message.Message(id, im.text, date, im.author)
      process.send(ctx.db, storage.Push(m))
      io.debug(m)
      wisp.created()
    }
    Error(err) -> {
      io.debug(err)
      wisp.bad_request()
    }
  }
}

pub fn get_message(id: String, ctx: Context) -> Response {
  let g = fn(s: Subject(Result(e, Nil))) { storage.Get(id, s) }
  case process.call(ctx.db, g, 10) {
    Ok(m) -> wisp.json_response(json.to_string_builder(message.to_json(m)), 200)
    Error(_) -> wisp.not_found()
  }
}

pub fn home_page(_req: Request) -> Response {
  let body = div([], [p([], [text("Hello Joe 2")])])
  wisp.html_response(to_string_builder(body), 200)
}
