const { HTTP } = require("./http");

export function addRemoteProps(props) {
  return new Promise((resolve, reject) => {
    let remoteProps = Array.prototype.concat.apply(
      [],
      props.handlerPath.map((c) => c.remoteProps).filter((p) => p)
    );

    remoteProps = remoteProps
      .map((spec_fun) => spec_fun(props))
      .filter((specs) => specs)
      .filter(
        (specs) => !props[specs.prop] || props[specs.prop].url != specs.url
      );

    if (remoteProps.length == 0) return resolve(props);

    const promise_mapper = (spec) => {
      return HTTP.get(spec.url).then((res) => {
        spec.value = res;
        return spec;
      });
    };

    const reducer = (acc, spec) => {
      // spec = url: '/api/orders', value: ORDERS, prop: 'user'}
      acc[spec.prop] = { url: spec.url, value: spec.value };
      return acc;
    };

    const promise_array = remoteProps.map(promise_mapper);
    return Promise.all(promise_array)
      .then((xs) => xs.reduce(reducer, props), reject)
      .then((p) => {
        // recursively call remote props, because props computed from
        // previous queries can give the missing data/props necessary
        // to define another query
        return addRemoteProps(p).then(resolve, reject);
      }, reject);
  });
}
