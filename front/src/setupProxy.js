const { createProxyMiddleware } = require("http-proxy-middleware");

module.exports = function (app) {
  if (process.env.NODE_ENV != "production") {
    app.use(
      "/api",
      createProxyMiddleware({
        target: "http://localhost:8080",
        changeOrigin: true,
        pathRewrite: (path, _req) => {
          return path.replace("/api", "");
        },
      })
    );
  }
};
