import { apiBaseUrl } from "./index";

const app = document.querySelector("#app");

if (app) {
  app.textContent = `API: ${apiBaseUrl()}`;
}
