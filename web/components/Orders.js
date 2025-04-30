const createReactClass = require("create-react-class");
const React = require("react");
const { HTTP } = require("../http/http");
const { remoteProps } = require("../http/remoteProps");
const { cn } = require("../utils/updateJsxzClass");

export const Orders = createReactClass({
  getInitialState() {
    return { searchKeyword: "" };
  },
  statics: {
    remoteProps: [remoteProps.orders],
  },
  refreshData(query) {
    delete this.props.orders.url;
    this.props.GoTo("orders", null, query);
    window.scrollTo(0, 0);
  },
  async onDeleteOrder(orderId) {
    const responseCode = await this.props.loader(async () =>
      HTTP.delete(`/api/orders/${orderId}`)
    );

    if (responseCode === 204) this.refreshData();
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
  parseSearchKeyword() {
    const [key, value] = this.state.searchKeyword.split(":");
    return { [key]: value };
  },
  onPaginate(page) {
    return (e) => {
      e.preventDefault();
      this.refreshData({ ...this.parseSearchKeyword(), page });
    };
  },
  onChangeSearch(e) {
    this.setState({ searchKeyword: e.target.value });
  },
  onSearch(e) {
    e.preventDefault();
    this.refreshData(this.parseSearchKeyword());
  },
  render() {
    const { orders: ordersResponse } = this.props;
    const orders = ordersResponse?.value?.orders;
    const currentPage = ordersResponse?.value?.page;
    const pagesCount = Math.ceil(
      ordersResponse?.value?.total_count / ordersResponse?.value?.rows
    );

    return (
      <JSXZ in="orders" sel=".container">
        <Z sel=".form-container">
          <JSXZ in="orders" sel=".search-form-block" onSubmit={this.onSearch}>
            <Z
              in="orders"
              sel=".form-input"
              value={this.state.searchKeyword}
              onChange={this.onChangeSearch}
            ></Z>
          </JSXZ>
        </Z>
        <Z sel=".tab-body">
          {orders?.map((order, index) => (
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
        <Z sel=".pagination">
          {new Array(pagesCount).fill(null).map((_, index) => (
            <JSXZ
              key={index}
              in="orders"
              sel=".pagination-btn"
              className={cn(classNameZ, {
                "pagination-btn-selected": index === currentPage,
              })}
              onClick={this.onPaginate(index)}
            >
              {index + 1}
            </JSXZ>
          ))}
        </Z>
      </JSXZ>
    );
  },
});
