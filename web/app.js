require("!!file-loader?name=[name].[ext]!./index.html");
require("./webflow/css/tuto.webflow.css");
const ReactDOM = require("react-dom");
const React = require("react");
const { getBrowserState } = require("./router/browserState");
const { Child } = require("./components/Child");
const { ErrorPage } = require("./components/ErrorPage");

function onPathChange() {
  const { browserState } = getBrowserState();
  const { route } = browserState;

  const component = route ? (
    <Child {...browserState} />
  ) : (
    <ErrorPage message={"Not Found"} code={404} />
  );

  ReactDOM.render(component, document.getElementById("root"));
}

window.addEventListener("popstate", () => onPathChange());

onPathChange();
