const React = require("react");
const createReactClass = require("create-react-class");

export const Header = createReactClass({
  render() {
    return (
      <JSXZ in="orders" sel=".header">
        <Z sel=".header-container">
          <this.props.Child {...this.props} />
        </Z>
      </JSXZ>
    );
  },
});
