require("!!file-loader?name=[name].[ext]!../index.html");
require("../webflow/css/tuto.webflow.css");
require("../webflow/css/modal.css");
const ReactDOM = require("react-dom");
const React = require("react");
const { getBrowserState } = require("../router/browserState");
const { Child } = require("./Child");
const { ErrorPage } = require("./ErrorPage");
const { addRemoteProps } = require("../http/addRemoteProps");

// TODO: replace browser state
var browserState = {};

function inferPropsChange(path, query, cookies) {
  // the second part of the onPathChange function have been moved here
  browserState = {
    ...browserState,
    path: path,
    qs: query,
    Link: Link,
    Child: Child,
  };

  var route, routeProps;
  for (var key in routes) {
    routeProps = routes[key].match(path, query);
    if (routeProps) {
      route = key;
      break;
    }
  }

  if (!route) {
    return new Promise((res, reject) => reject({ http_code: 404 }));
  }
  browserState = {
    ...browserState,
    ...routeProps,
    route: route,
  };

  return addRemoteProps(browserState).then((props) => {
    browserState = props;
  });
}

export default {
  reaxt_server_render(params, render) {
    inferPropsChange(params.path, params.query, params.cookies).then(
      () => {
        render(<Child {...browserState} />);
      },
      (err) => {
        render(
          <ErrorPage message={"Not Found :" + err.url} code={err.http_code} />,
          err.http_code
        );
      }
    );
  },
  reaxt_client_render(initialProps, render) {
    browserState = initialProps;
    Link.renderFunc = render;
    window.addEventListener("popstate", () => {
      Link.onPathChange();
    });
    Link.onPathChange();
  },
};
