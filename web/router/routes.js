const { Layout } = require("../components/Layout");
const { Header } = require("../components/Header");
const { Orders } = require("../components/Orders");
const { Order } = require("../components/Order");

export const routes = {
  orders: {
    path: (params) => {
      return "/";
    },
    match: (path, qs) => {
      return path == "/" && { handlerPath: [Layout, Header, Orders] };
    },
  },
  order: {
    path: (params) => {
      return "/order/" + params;
    },
    match: (path, qs) => {
      const r = new RegExp("/order/([^/]*)$").exec(path);
      return r && { handlerPath: [Layout, Header, Order], order_id: r[1] };
    },
  },
};
