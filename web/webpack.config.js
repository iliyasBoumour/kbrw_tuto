var path = require("path"),
  MiniCssExtractPlugin = require("mini-css-extract-plugin"),
  CssMinimizerPlugin = require("css-minimizer-webpack-plugin");

var client_config = {
  entry: "reaxt/client_entry_addition",
  devtool: "source-map",
  output: {
    path: path.join(__dirname, "../priv/static"),
    filename: "[name].[fullhash].js",
    chunkFilename: "chunk/client.[chunkhash].js",
    clean: true,
    publicPath: "/public/",
  },
  optimization: {
    splitChunks: {
      cacheGroups: {
        styles: {
          name: "styles",
          test: /\.css$/,
          chunks: "all",
          enforce: true,
        },
      },
    },
    minimizer: [`...`, new CssMinimizerPlugin()],
  },
  plugins: [new MiniCssExtractPlugin({ insert: "", filename: "[name].css" })],
  module: {
    rules: [
      {
        test: /.js?$/,
        use: {
          loader: "babel-loader",
          options: {
            presets: [
              ["@babel/preset-env", { targets: "defaults" }],
              "@babel/preset-react",
              ["@kbrw/jsxz", { dir: "webflow" }],
            ],
          },
        },
        exclude: /node_modules/,
      },
    ],
  },
};

var server_config = Object.assign(Object.assign({}, client_config), {
  target: "node",
  entry: "reaxt/react_server",
  output: {
    clean: true,
    path: path.join(__dirname, "../priv/react_servers"), //typical output on the default directory served by Plug.Static
    filename: "server.js", //dynamic name for long term caching, or code splitting, use WebPack.file_of(:main) to get it
    chunkFilename: "chunk/server.[id].js",
  },
});

// optimisation : ONLY EMIT files for client compilation, all file-loader should not emit files on server compilation
server_config.module = {
  rules: server_config.module.rules.map((rule) => {
    return {
      ...rule,
      use: (Array.isArray(rule.use) ? rule.use : [rule.use]).map((use) => {
        return {
          ...use,
          options:
            use.loader === "file-loader"
              ? { ...use.options, emitFile: false }
              : use.options,
        };
      }),
    };
  }),
};

client_config.module.rules.push({
  test: /\.(css)$/,
  use: [{ loader: MiniCssExtractPlugin.loader }, { loader: "css-loader" }],
});
server_config.module.rules.push({
  test: /\.(css)$/,
  use: [{ loader: "null-loader" }],
});

module.exports = [client_config, server_config];
