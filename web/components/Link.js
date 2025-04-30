const React = require("react");
const createReactClass = require("create-react-class");

var Link = createReactClass({
  statics: {
    renderFunc: null, //render function to use (differently set depending if we are server sided or client sided)
    GoTo(route, params, query) {
      // function used to change the path of our browser
      var path = routes[route].path(params);
      var qs = Qs.stringify(query);
      var url = path + (qs == "" ? "" : "?" + qs);
      history.pushState({}, "", url);
      Link.onPathChange();
    },
    onPathChange() {
      //Updated onPathChange
      var path = location.pathname;
      var qs = Qs.parse(location.search.slice(1));
      var cookies = Cookie.parse(document.cookie);
      inferPropsChange(path, qs, cookies).then(
        //inferPropsChange download the new props if the url query changed as done previously
        () => {
          Link.renderFunc(<Child {...browserState} />); //if we are on server side we render
        },
        ({ http_code }) => {
          Link.renderFunc(
            <ErrorPage message={"Not Found"} code={http_code} />,
            http_code
          ); //idem
        }
      );
    },
    LinkTo: (route, params, query) => {
      var qs = Qs.stringify(query);
      return routes[route].path(params) + (qs == "" ? "" : "?" + qs);
    },
  },
  onClick(ev) {
    ev.preventDefault();
    Link.GoTo(this.props.to, this.props.params, this.props.query);
  },
  render() {
    //render a <Link> this way transform link into href path which allows on browser without javascript to work perfectly on the website
    return (
      <a
        href={Link.LinkTo(this.props.to, this.props.params, this.props.query)}
        onClick={this.onClick}
      >
        {this.props.children}
      </a>
    );
  },
});
