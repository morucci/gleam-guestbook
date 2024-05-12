import gleam/io
import guestbook_shared/message

pub fn main() {
  io.debug(message.Message(1, "some text", 1234, "fabien"))
}
