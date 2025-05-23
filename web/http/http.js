var localhost = require("reaxt/config").localhost;
const XMLHttpRequest = require("xhr2");

export const HTTP = new (function () {
  this.get = (url) => this.req("GET", url);
  this.delete = (url) => this.req("DELETE", url);
  this.post = (url, data) => this.req("POST", url, data);
  this.put = (url, data) => this.req("PUT", url, data);

  this.req = (method, url, data) =>
    new Promise((resolve, reject) => {
      const req = new XMLHttpRequest();
      url = typeof window !== "undefined" ? url : localhost + url;
      req.open(method, url);
      req.responseType = "text";
      req.setRequestHeader("accept", "application/json,*/*;0.8");
      req.setRequestHeader("content-type", "application/json");
      req.onload = () => {
        if (req.status >= 200 && req.status < 300) {
          resolve(req.responseText ? JSON.parse(req.responseText) : req.status);
        } else {
          reject({ http_code: req.status });
        }
      };

      req.onerror = (err) => {
        reject({ http_code: req.status });
      };

      req.send(data && JSON.stringify(data));
    });
})();
