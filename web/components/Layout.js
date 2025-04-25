const React = require("react");
const createReactClass = require("create-react-class");
const { cn } = require("../utils/updateJsxzClass");
const { DeleteModal } = require("./DeleteModal");
const { LoaderModal } = require("./LoaderModal");

export const Layout = createReactClass({
  getInitialState() {
    return { modal: null };
  },
  async loader(promise) {
    this.setState({ modal: { type: "load" } });
    try {
      const result = await promise();
      return result;
    } catch (e) {
      console.log("error", e);
    } finally {
      this.setState({ modal: null });
    }
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
      load: (props) => <LoaderModal {...props} />,
    }[this.state.modal?.type];

    modal_component = modal_component?.(this.state.modal);

    const props = { ...this.props, modal: this.modal, loader: this.loader };

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
