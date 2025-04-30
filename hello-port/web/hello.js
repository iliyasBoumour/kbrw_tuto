var log = require("@kbrw/node_erlastic").log;

require("@kbrw/node_erlastic").server(function (
  term,
  from,
  // current_amount: get initialized when the genServer got init and then send the first message
  // it's equivalent to genServer state
  initialState,
  done
) {
  // GenServer.call HelloPort, :hello
  // term: {"type":"Atom","value":"hello"}
  if (term == "hello") return done("reply", "Hello world !");
  if (term == "what") return done("reply", "What what ?");
  if (term == "kbrw") {
    if (!initialState) return done("reply", "You should init state first");
    return done("reply", initialState, initialState - 2);
  }

  // GenServer.cast HelloPort, {:kbrw, 2}
  // term: {"0":{"type":"Atom","value":"kbrw"},"1":2,"type":"Tuple","length":2,"value":{"0":{"type":"Atom","value":"kbrw"},"1":2}}
  // it returns the "GenServer" new state as second arg
  if (term[0] == "kbrw") return done("noreply", term[1]);

  throw new Error("unexpected request");
});
