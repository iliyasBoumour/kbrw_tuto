const React = require("react");
const createReactClass = require("create-react-class");
const { cn } = require("../utils/updateJsxzClass");
const { DeleteModal } = require("./DeleteModal");

export const Layout = createReactClass({
  getInitialState() {
    return { modal: null };
  },
  modal(spec) {
    this.setState({
      modal: {
        ...spec,
        callback: (res) => {
          this.setState({ modal: null }, () => {
            if (spec.callback) spec.callback(res);
          });
        },
      },
    });
  },
  render() {
    let modal_component = {
      delete: (props) => <DeleteModal {...props} />,
    }[this.state.modal?.type];

    modal_component = modal_component?.(this.state.modal);

    const props = {
      ...this.props,
      modal: this.modal,
    };

    return (
      <JSXZ in="orders" sel=".layout">
        <Z
          sel=".modal-wrapper"
          className={cn(classNameZ, { hidden: !modal_component })}
        >
          {modal_component}
        </Z>
        <Z sel=".layout-container">
          <this.props.Child {...props} />
        </Z>
      </JSXZ>
    );
  },
});
