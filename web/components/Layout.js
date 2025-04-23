const React = require("react");
const createReactClass = require("create-react-class");

export const Layout = createReactClass({
  render() {
    return (
      <JSXZ in="orders" sel=".layout">
        <Z sel=".layout-container">
          <this.props.Child {...this.props} />
        </Z>
      </JSXZ>
    );
  },
});
