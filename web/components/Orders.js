import { HTTP } from "../http/http";

const createReactClass = require("create-react-class");
const React = require("react");
const { remoteProps } = require("../http/remoteProps");

export const Orders = createReactClass({
  statics: {
    remoteProps: [remoteProps.orders],
  },
  refrechData() {
    delete this.props.orders.url;
    dispatchEvent(new PopStateEvent("popstate"));
  },
  async onDeleteOrder(orderId) {
    const responseCode = await this.props.loader(async () =>
      HTTP.delete(`/api/orders/${orderId}`)
    );

    if (responseCode === 204) this.refrechData();
  },
  showDeleteModal(orderId) {
    return () => {
      this.props.modal({
        type: "delete",
        title: "Order deletion",
        message: `Are you sure you want to delete this ?`,
        callback: async (value) => value && this.onDeleteOrder(orderId),
      });
    };
  },
  onShowOrderDetails(orderId) {
    return () => this.props.GoTo("order", orderId);
  },
  render() {
    const { orders } = this.props;

    return (
      <JSXZ in="orders" sel=".container">
        <Z in="orders" sel=".tab-body">
          {orders.value?.map((order, index) => (
            <JSXZ
              data-index={index}
              key={order.remoteid}
              in="orders"
              sel=".tab-line"
            >
              <Z sel=".col-1 .p">{order.remoteid}</Z>
              <Z sel=".col-2 .p">{order.custom.customer.full_name}</Z>
              <Z sel=".col-3 .p">{order.custom.billing_address.street[0]}</Z>
              <Z sel=".col-4 .p">{order.custom.items.length}</Z>
              <Z sel=".col-5 .icon" onClick={this.onShowOrderDetails(order.id)}>
                <ChildrenZ />
              </Z>
              <Z sel=".col-6 .order-status">{order.status.state}</Z>
              <Z sel=".col-6 .payment-method">
                {order.custom.magento.payment.method}
              </Z>
              <Z sel=".col-7 .icon" onClick={this.showDeleteModal(order.id)}>
                <ChildrenZ />
              </Z>
            </JSXZ>
          ))}
        </Z>
      </JSXZ>
    );
  },
});
