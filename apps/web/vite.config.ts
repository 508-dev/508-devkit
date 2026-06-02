import { defineConfig } from "vite";

export default defineConfig({
  server: {
    host: process.env.WEB_HOST ?? "127.0.0.1",
    port: Number(process.env.WEB_PORT ?? "8730"),
  },
});
