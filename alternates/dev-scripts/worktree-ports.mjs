#!/usr/bin/env node
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { resolve } from "node:path";

const BASE_PORT = 8700;
const SPAN = 1000;
const PORT_BLOCK_SIZE = 100;
const OFFSETS = {
  API_PORT: 20,
  WEB_PORT: 30,
  WORKER_HEALTH_PORT: 35,
  POSTGRES_HOST_PORT: 40,
  REDIS_HOST_PORT: 50,
};

function worktreeRoot() {
  try {
    return execFileSync("git", ["rev-parse", "--show-toplevel"], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return process.cwd();
  }
}

function portBlock(root) {
  const digest = createHash("sha256").update(resolve(root)).digest("hex");
  return BASE_PORT + ((Number.parseInt(digest.slice(0, 8), 16) % (SPAN / PORT_BLOCK_SIZE)) * PORT_BLOCK_SIZE);
}

function envValues() {
  const base = portBlock(worktreeRoot());
  const values = Object.fromEntries(Object.entries(OFFSETS).map(([key, offset]) => [key, String(base + offset)]));
  values.POSTGRES_URL = `postgresql://app:app@127.0.0.1:${values.POSTGRES_HOST_PORT}/app`;
  values.DATABASE_URL = values.POSTGRES_URL;
  values.REDIS_URL = `redis://127.0.0.1:${values.REDIS_HOST_PORT}/0`;
  values.NEXT_PUBLIC_API_BASE_URL = `http://127.0.0.1:${values.API_PORT}`;
  return values;
}

const command = process.argv[2] ?? "env";
const values = envValues();

if (command === "env") {
  for (const [key, value] of Object.entries(values)) {
    // biome-ignore lint/suspicious/noConsole: CLI output is consumed by humans and shell scripts.
    console.log(`${key}=${value}`);
  }
} else if (command === "export") {
  for (const [key, value] of Object.entries(values)) {
    // biome-ignore lint/suspicious/noConsole: CLI output is consumed by humans and shell scripts.
    console.log(`export ${key}=${value}`);
  }
} else {
  // biome-ignore lint/suspicious/noConsole: CLI usage errors belong on stderr.
  console.error("usage: worktree-ports.mjs [env|export]");
  process.exit(2);
}
