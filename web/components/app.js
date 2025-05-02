require("!!file-loader?name=[name].[ext]!../index.html");
require("../webflow/css/tuto.webflow.css");
require("../webflow/css/modal.css");
const ReactDOM = require("react-dom");
const React = require("react");
const { getBrowserState } = require("../router/browserState");
const { Child } = require("./Child");
const { ErrorPage } = require("./ErrorPage");
const { addRemoteProps } = require("../http/addRemoteProps");

export function onPathChange() {
  let { browserState } = getBrowserState();

  addRemoteProps(browserState).then(
    (props) => {
      browserState = props;
      console.log(browserState);

      ReactDOM.render(
        <Child {...browserState} />,
        document.getElementById("root")
      );
    },
    (res) => {
      ReactDOM.render(
        <ErrorPage message={"Shit happened"} code={res.http_code} />,
        document.getElementById("root")
      );
    }
  );
}

window.addEventListener("popstate", () => onPathChange());

onPathChange();
