const React = require("react");
const createReactClass = require("create-react-class");

export const Child = createReactClass({
  render() {
    console.log("child props", this.props);
    const [ChildHandler, ...rest] = this.props.handlerPath;
    return <ChildHandler {...this.props} handlerPath={rest} />;
  },
});
