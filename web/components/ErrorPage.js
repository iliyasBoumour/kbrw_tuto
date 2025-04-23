const React = require("react");
const createReactClass = require("create-react-class");

export const ErrorPage = createReactClass({
  render() {
    const { code, message } = this.props;
    return <h1>{`Error ${code}: ${message}`}</h1>;
  },
});
