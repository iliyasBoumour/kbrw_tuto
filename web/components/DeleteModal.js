const React = require("react");
const createReactClass = require("create-react-class");

export const DeleteModal = createReactClass({
  onConfirm() {
    return this.props.callback?.(true);
  },
  onCancel() {
    return this.props.callback?.(false);
  },
  render() {
    return (
      <JSXZ in="confirmation-modal" sel=".modal-wrapper">
        <Z sel=".modal-title">{this.props.title}</Z>
        <Z sel=".modal-message">{this.props.message}</Z>
        <Z sel=".cancel-btn" onClick={this.onCancel}>
          <ChildrenZ />
        </Z>
        <Z sel=".confirm-btn" onClick={this.onConfirm}>
          <ChildrenZ />
        </Z>
      </JSXZ>
    );
  },
});
