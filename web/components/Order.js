const createReactClass = require("create-react-class");
const React = require("react");
const { remoteProps } = require("../http/remoteProps");

export const Order = createReactClass({
  statics: {
    remoteProps: [remoteProps.order],
  },

  render() {
    const {
      order: { value: order },
      Link,
    } = this.props;

    const goBack = () => (e) => {
      e.preventDefault();
      Link.GoTo("orders");
    };

    return (
      <JSXZ in="order" sel=".container">
        <Z sel=".client-name">{order.custom.customer.full_name}</Z>
        <Z sel=".client-address">{order.custom.billing_address.street[0]}</Z>
        <Z sel=".command-number">{order.custom.order_number}</Z>

        <Z sel=".tab-body">
          {order.custom.items.map((item) => (
            <JSXZ key={item.product_ean} in="order" sel=".tab-line">
              <Z sel=" .col-1 .p">{item.label_ug}</Z>
              <Z sel=" .col-2 .p">{item.quantity_to_fetch}</Z>
              <Z sel=" .col-3 .p">{item.unit_price}</Z>
              <Z sel=" .col-4 .p">{item.quantity_to_fetch * item.unit_price}</Z>
            </JSXZ>
          ))}
        </Z>
        <Z sel=".footer-container .w-inline-block" onClick={goBack()}>
          <ChildrenZ />
        </Z>
      </JSXZ>
    );
  },
});
