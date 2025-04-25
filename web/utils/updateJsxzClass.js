export const cn = function () {
  const args = arguments,
    classes = {};
  for (let i in args) {
    const arg = args[i];
    if (!arg) continue;
    if ("string" === typeof arg || "number" === typeof arg) {
      arg
        .split(" ")
        .filter((c) => c != "")
        .map((c) => {
          classes[c] = true;
        });
    } else if ("object" === typeof arg) {
      for (let key in arg) classes[key] = arg[key];
    }
  }
  return Object.keys(classes)
    .map((k) => (classes[k] && k) || "")
    .join(" ");
};
