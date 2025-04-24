const Qs = require("qs");

export const remoteProps = {
  orders: (props) => {
    const query = Qs.stringify(props.qs);
    return {
      url: "/api/orders" + (query == "" ? "" : "?" + query),
      prop: "orders",
    };
  },
  order: (props) => {
    return {
      url: "/api/orders/" + props.order_id,
      prop: "order",
    };
  },
};
