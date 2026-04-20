#!/usr/bin/env node
// Node.js entry point for `agentize`.
// Finds a bash that can run install.sh, regardless of platform.
// On Unix/macOS: /usr/bin/env bash. On Windows: Git Bash or WSL.
"use strict";

const { spawnSync } = require("child_process");
const { existsSync } = require("fs");
const path = require("path");

const repoRoot = path.resolve(__dirname, "..");
const installSh = path.join(repoRoot, "install.sh");

if (!existsSync(installSh)) {
  console.error(`agentize: install.sh not found at ${installSh}`);
  process.exit(1);
}

function tryRun(cmd, args) {
  try {
    const r = spawnSync(cmd, args, { stdio: "inherit" });
    if (r.error && r.error.code === "ENOENT") return { ran: false };
    return { ran: true, status: r.status == null ? 1 : r.status };
  } catch {
    return { ran: false };
  }
}

const forwarded = process.argv.slice(2);
const candidates = [];

if (process.platform === "win32") {
  // Git Bash on Windows
  const gitBashPaths = [
    "C:\\Program Files\\Git\\bin\\bash.exe",
    "C:\\Program Files (x86)\\Git\\bin\\bash.exe",
    process.env.USERPROFILE
      ? path.join(process.env.USERPROFILE, "AppData", "Local", "Programs", "Git", "bin", "bash.exe")
      : null,
  ].filter(Boolean);
  for (const p of gitBashPaths) {
    if (existsSync(p)) candidates.push({ cmd: p, args: [installSh, ...forwarded] });
  }
  // Fallback: bash on PATH (Git Bash, MSYS, Cygwin)
  candidates.push({ cmd: "bash", args: [installSh, ...forwarded] });
  // Last resort: WSL — translate path
  candidates.push({ cmd: "wsl.exe", args: ["bash", "-c", `'${installSh.replace(/\\/g, "/")}' ${forwarded.map(a => `'${a}'`).join(" ")}`] });
} else {
  candidates.push({ cmd: "bash", args: [installSh, ...forwarded] });
}

for (const c of candidates) {
  const r = tryRun(c.cmd, c.args);
  if (r.ran) process.exit(r.status);
}

console.error(
  [
    "",
    "agentize needs bash, and none was found on PATH.",
    "",
    process.platform === "win32"
      ? "Install Git Bash (https://git-scm.com/downloads) or enable WSL."
      : "Install bash (it ships with every major distro and macOS).",
    "",
  ].join("\n"),
);
process.exit(1);
