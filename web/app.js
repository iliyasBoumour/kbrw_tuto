require("!!file-loader?name=[name].[ext]!./index.html");
var ReactDOM = require("react-dom");
var React = require("react");
var createReactClass = require("create-react-class");
require("./webflow/css/tuto.webflow.css");

var { orders } = require("./data");

var Page = createReactClass({
  render() {
    return (
      <JSXZ in="orders" sel=".body">
        <ChildrenZ />
        <Z in="orders" sel=".tab-body">
          {orders.map((order) => (
            <JSXZ key={order.remoteid} in="orders" sel=".tab-line">
              <Z sel=" .col-1 .p">{order.remoteid}</Z>
              <Z sel=" .col-2 .p">{order.custom.customer.full_name}</Z>
              <Z sel=" .col-3 .p">{order.custom.billing_address}</Z>
              <Z sel=" .col-4 .p">{order.items}</Z>
            </JSXZ>
          ))}
        </Z>
      </JSXZ>
    );
  },
});

ReactDOM.render(<Page />, document.getElementById("root"));
