import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";

const root = new URL("../prototype/", import.meta.url);
const port = Number(process.env.PORT || 4318);

const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8"
};

const server = createServer(async (req, res) => {
  try {
    const requestPath = req.url === "/" ? "/index.html" : req.url || "/index.html";
    const safePath = normalize(requestPath).replace(/^(\.\.[/\\])+/, "");
    const fileUrl = new URL(`.${safePath}`, root);
    const data = await readFile(fileUrl);
    const type = mimeTypes[extname(fileUrl.pathname)] || "application/octet-stream";
    res.writeHead(200, { "Content-Type": type });
    res.end(data);
  } catch (error) {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end(`Not found: ${error instanceof Error ? error.message : "unknown error"}`);
  }
});

server.listen(port, "127.0.0.1", () => {
  const path = join(process.cwd(), "plugins", "yiji-focus-float", "prototype");
  console.log(`Yiji Focus Float running on http://127.0.0.1:${port} from ${path}`);
});
