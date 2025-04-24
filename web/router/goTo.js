const Qs = require("qs");
const { routes } = require("./routes");
const { onPathChange } = require("../app");

export const GoTo = (route, params, query) => {
  const qs = Qs.stringify(query);
  const url = routes[route].path(params) + (qs == "" ? "" : "?" + qs);
  history.pushState({}, "", url);
  onPathChange();
};
