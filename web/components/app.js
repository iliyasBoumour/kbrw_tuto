require("../webflow/css/tuto.webflow.css");
require("../webflow/css/modal.css");
const React = require("react");
const createReactClass = require("create-react-class");
const Qs = require("qs");
const Cookie = require("cookie");
const { routes } = require("../router/routes");
const { Child } = require("./Child");
const { ErrorPage } = require("./ErrorPage");
const { addRemoteProps } = require("../http/addRemoteProps");

const Link = createReactClass({
  statics: {
    renderFunc: null, //render function to use (differently set depending if we are server sided or client sided)
    GoTo(route, params, query) {
      // function used to change the path of our browser
      var path = routes[route].path(params);
      var qs = Qs.stringify(query);
      var url = path + (qs == "" ? "" : "?" + qs);
      history.pushState({}, "", url);
      Link.onPathChange();
    },
    onPathChange() {
      //Updated onPathChange
      var path = location.pathname;
      var qs = Qs.parse(location.search.slice(1));
      var cookies = Cookie.parse(document.cookie);
      inferPropsChange(path, qs, cookies).then(
        //inferPropsChange download the new props if the url query changed as done previously
        () => {
          Link.renderFunc(<Child {...browserState} />); //if we are on server side we render
        },
        ({ http_code }) => {
          Link.renderFunc(
            <ErrorPage message={"Not Found"} code={http_code} />,
            http_code
          ); //idem
        }
      );
    },
    LinkTo: (route, params, query) => {
      var qs = Qs.stringify(query);
      return routes[route].path(params) + (qs == "" ? "" : "?" + qs);
    },
  },
  onClick(ev) {
    ev.preventDefault();
    Link.GoTo(this.props.to, this.props.params, this.props.query);
  },
  render() {
    //render a <Link> this way transform link into href path which allows on browser without javascript to work perfectly on the website
    return (
      <a
        href={Link.LinkTo(this.props.to, this.props.params, this.props.query)}
        onClick={this.onClick}
      >
        {this.props.children}
      </a>
    );
  },
});

// TODO: replace browser stat
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
