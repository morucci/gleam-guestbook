# guestbook-back

gleam run
curl http://localhost:8000/message/1
curl -v -H 'content-type:application/json' http://localhost:8000/message -d '{"text":"test", "author":"Fabien"}'
