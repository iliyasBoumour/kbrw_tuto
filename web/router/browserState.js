const Qs = require("qs");
const Cookie = require("cookie");
const { routes } = require("./routes");
const { Child } = require("../components/Child");

let browserState = { Child: Child };

export const getBrowserState = () => {
  const path = location.pathname;
  const qs = Qs.parse(location.search.slice(1));
  const cookies = Cookie.parse(document.cookie);
  let route, routeProps;

  browserState = { ...browserState, path, qs, cookie: cookies };

  for (let key in routes) {
    routeProps = routes[key].match(path, qs);

    if (routeProps) {
      route = key;
      break;
    }
  }

  browserState = { ...browserState, ...routeProps, route };

  return { browserState };
};
