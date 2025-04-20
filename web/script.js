const showAlert = () => {
  element = <div>Hey i was created from react! {10 + 10}</div>;

  ReactDOM.render(element, document.getElementById("root"));
};

document.getElementById("alertBtn").onclick = showAlert;
