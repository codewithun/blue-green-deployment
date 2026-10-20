const express = require("express");

const app = express();
const port = process.env.PORT || 3000;
const version = process.env.APP_VERSION || "v1";
const color = process.env.APP_COLOR || "blue";

app.get("/", (req, res) => {
  const response = {
    application: "blue-green-demo",
    version,
    color,
    status: "running",
    timestamp: new Date().toISOString()
  };

  if (version === "v2") {
    response.release = "green-release";
    response.feature = "deployment-v2";
  }

  res.json(response);
});

app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    version
  });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`App ${version} listening on port ${port}`);
});
