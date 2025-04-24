const createReactClass = require("create-react-class");
const React = require("react");
const { remoteProps } = require("../http/remoteProps");

export const Orders = createReactClass({
  statics: {
    remoteProps: [remoteProps.orders],
  },
  render() {
    const {
      GoTo,
      orders: { value: orders },
    } = this.props;

    const goToOrder = (orderId) => () => GoTo("order", orderId);

    return (
      <JSXZ in="orders" sel=".container">
        <Z in="orders" sel=".tab-body">
          {orders.map((order) => (
            <JSXZ key={order.remoteid} in="orders" sel=".tab-line">
              <Z sel=" .col-1 .p">{order.remoteid}</Z>
              <Z sel=" .col-2 .p">{order.custom.customer.full_name}</Z>
              <Z sel=" .col-3 .p">{order.custom.billing_address.street[0]}</Z>
              <Z sel=" .col-4 .p">{order.custom.items.length}</Z>
              <Z sel=" .col-5" onClick={goToOrder(order.id)}>
                <ChildrenZ />
              </Z>
              <Z sel=".col-6 .order-status">{order.status.state}</Z>
              <Z sel=".col-6 .payment-method">
                {order.custom.magento.payment.method}
              </Z>
            </JSXZ>
          ))}
        </Z>
      </JSXZ>
    );
  },
});
