const createReactClass = require("create-react-class");
const React = require("react");
const { orders } = require("../mocks/data");

export const Orders = createReactClass({
  render() {
    return (
      <JSXZ in="orders" sel=".container">
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
