#!/usr/bin/env bun

import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, existsSync, appendFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

type FlagMap = Record<string, string | boolean>;

const ROOT_DIR = path.dirname(fileURLToPath(import.meta.url));

const REPO_AGENTS_TEMPLATE = path.join(ROOT_DIR, "templates", "repo", "AGENTS.md.template");
const REPO_NOTES_TEMPLATE = path.join(ROOT_DIR, "templates", "repo", "AGENT_NOTES.md.template");
const GLOBAL_AGENTS_TEMPLATE = path.join(ROOT_DIR, "templates", "global", "AGENTS.md.template");
const GLOBAL_NOTES_TEMPLATE = path.join(ROOT_DIR, "templates", "global", "AGENT_NOTES_GLOBAL.md.template");

function usage(): void {
  console.log(`agents-config Bun CLI

Usage:
  bun run agents setup --workspace-root <path> --repo-root <path>
  bun run agents workspace-init --workspace-root <path>
  bun run agents apply --workspace-root <path> --repo-root <path>
  bun run agents validate

Notes:
  - This CLI is deterministic and template-driven.
  - AGENTS.md remains tracked by default.
  - Local notes are untracked by default: AGENT_NOTES*.md and .agentsmd.
`);
}

function parseArgs(argv: string[]): { command: string; flags: FlagMap } {
  const command = argv[0] ?? "";
  const flags: FlagMap = {};

  for (let i = 1; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith("--")) {
      continue;
    }

    const eq = token.indexOf("=");
    if (eq > -1) {
      const key = token.slice(2, eq);
      const value = token.slice(eq + 1);
      flags[key] = value;
      continue;
    }

    const key = token.slice(2);
    const next = argv[i + 1];
    if (next && !next.startsWith("--")) {
      flags[key] = next;
      i += 1;
    } else {
      flags[key] = true;
    }
  }

  return { command, flags };
}

function mustFlag(flags: FlagMap, key: string): string {
  const value = flags[key];
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`Missing required flag --${key}`);
  }
  return value;
}

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

function ensureFile(pathname: string): void {
  if (!existsSync(pathname)) {
    throw new Error(`Missing required file: ${pathname}`);
  }
}

function renderTemplate(templatePath: string, outputPath: string, workspaceRoot: string): void {
  if (existsSync(outputPath)) {
    return;
  }
  const content = readFileSync(templatePath, "utf8")
    .replaceAll("{{WORKSPACE_ROOT}}", workspaceRoot)
    .replaceAll("{{DATE}}", today());
  writeFileSync(outputPath, content, "utf8");
}

function ensureLine(filePath: string, line: string): void {
  let existing = "";
  if (existsSync(filePath)) {
    existing = readFileSync(filePath, "utf8");
  } else {
    writeFileSync(filePath, "", "utf8");
  }

  const lines = existing.split(/\r?\n/).filter((item) => item.length > 0);
  if (!lines.includes(line)) {
    appendFileSync(filePath, `${line}\n`, "utf8");
  }
}

function runGit(args: string[]): { status: number; stdout: string; stderr: string } {
  const result = spawnSync("git", args, { encoding: "utf8" });
  return {
    status: result.status ?? 1,
    stdout: result.stdout ?? "",
    stderr: result.stderr ?? "",
  };
}

function isGitRepo(repoRoot: string): boolean {
  const result = runGit(["-C", repoRoot, "rev-parse", "--is-inside-work-tree"]);
  return result.status === 0;
}

function listTrackedLocalNotes(repoRoot: string): string[] {
  const result = runGit([
    "-C",
    repoRoot,
    "ls-files",
    "-z",
    "--",
    "AGENT_NOTES*.md",
    "**/AGENT_NOTES*.md",
    ".agentsmd",
    "**/.agentsmd",
  ]);

  if (result.status !== 0) {
    return [];
  }

  return result.stdout.split("\0").filter((entry) => entry.length > 0);
}

function untrackLocalNotes(repoRoot: string): void {
  if (!isGitRepo(repoRoot)) {
    return;
  }

  for (const trackedFile of listTrackedLocalNotes(repoRoot)) {
    runGit(["-C", repoRoot, "rm", "--cached", "--ignore-unmatch", "--", trackedFile]);
  }
}

function applyRepoPolicy(workspaceRoot: string, repoRoot: string): void {
  ensureFile(REPO_AGENTS_TEMPLATE);
  ensureFile(REPO_NOTES_TEMPLATE);

  mkdirSync(repoRoot, { recursive: true });

  const gitignorePath = path.join(repoRoot, ".gitignore");
  ensureLine(gitignorePath, "/docs/");
  ensureLine(gitignorePath, "AGENT_NOTES*.md");
  ensureLine(gitignorePath, ".agentsmd");

  renderTemplate(REPO_AGENTS_TEMPLATE, path.join(repoRoot, "AGENTS.md"), workspaceRoot);
  renderTemplate(REPO_NOTES_TEMPLATE, path.join(repoRoot, "AGENT_NOTES.md"), workspaceRoot);

  untrackLocalNotes(repoRoot);

  console.log(`Applied policy to: ${repoRoot}`);
  console.log("- ensured .gitignore: /docs/, AGENT_NOTES*.md, .agentsmd");
  console.log("- ensured AGENTS.md and AGENT_NOTES.md exist");
  console.log("- ensured AGENTS.md remains tracked for review guidance");
  console.log("- untracked AGENT_NOTES*.md/.agentsmd where previously tracked");
}

function workspaceInit(workspaceRoot: string): void {
  ensureFile(GLOBAL_AGENTS_TEMPLATE);
  ensureFile(GLOBAL_NOTES_TEMPLATE);

  mkdirSync(workspaceRoot, { recursive: true });

  const globalAgentsPath = path.join(workspaceRoot, "AGENTS.md");
  const globalNotesPath = path.join(workspaceRoot, "AGENT_NOTES_GLOBAL.md");

  renderTemplate(GLOBAL_AGENTS_TEMPLATE, globalAgentsPath, workspaceRoot);
  renderTemplate(GLOBAL_NOTES_TEMPLATE, globalNotesPath, workspaceRoot);

  console.log(`Initialized workspace policy in: ${workspaceRoot}`);
  console.log(`- ensured ${globalAgentsPath}`);
  console.log(`- ensured ${globalNotesPath}`);
}

function countLine(filePath: string, line: string): number {
  if (!existsSync(filePath)) {
    return 0;
  }
  return readFileSync(filePath, "utf8")
    .split(/\r?\n/)
    .filter((item) => item === line).length;
}

function isTracked(repoRoot: string, relPath: string): boolean {
  return runGit(["-C", repoRoot, "ls-files", "--error-unmatch", relPath]).status === 0;
}

function validateSetupConsistency(): void {
  const requiredFiles = [
    "setup_instructions.md",
    "setup_instructions_ubuntu.md",
    "setup_instructions_win.md",
    "README.md",
    "cli.ts",
    "package.json",
    path.join("templates", "global", "AGENTS.md.template"),
    path.join("templates", "global", "AGENT_NOTES_GLOBAL.md.template"),
    path.join("templates", "repo", "AGENTS.md.template"),
    path.join("templates", "repo", "AGENT_NOTES.md.template"),
  ];

  for (const relPath of requiredFiles) {
    ensureFile(path.join(ROOT_DIR, relPath));
  }

  const docs = [
    path.join(ROOT_DIR, "setup_instructions.md"),
    path.join(ROOT_DIR, "setup_instructions_ubuntu.md"),
    path.join(ROOT_DIR, "setup_instructions_win.md"),
  ];
  const requiredTokens = ["AGENT_NOTES*.md", ".agentsmd", "/docs/", "last_config_sync_date", "read-only", "Review guidelines"];
  for (const docPath of docs) {
    const content = readFileSync(docPath, "utf8");
    for (const token of requiredTokens) {
      if (!content.includes(token)) {
        throw new Error(`Missing token '${token}' in ${docPath}`);
      }
    }
  }

  const winDoc = readFileSync(path.join(ROOT_DIR, "setup_instructions_win.md"), "utf8");
  if (/<[^>]+>\//.test(winDoc)) {
    throw new Error("Windows setup doc contains Unix-style placeholder separators.");
  }

  const tmpRoot = mkdtempSync(path.join(os.tmpdir(), "agents-config-validate-"));
  const workspaceRoot = path.join(tmpRoot, "workspace");
  const repoRoot = path.join(workspaceRoot, "sample-repo");
  mkdirSync(repoRoot, { recursive: true });

  applyRepoPolicy(workspaceRoot, repoRoot);
  applyRepoPolicy(workspaceRoot, repoRoot);

  const gitignorePath = path.join(repoRoot, ".gitignore");
  if (countLine(gitignorePath, "/docs/") !== 1) {
    throw new Error("Non-idempotent /docs/ entry in generated .gitignore");
  }
  if (countLine(gitignorePath, "AGENT_NOTES*.md") !== 1) {
    throw new Error("Non-idempotent AGENT_NOTES*.md entry in generated .gitignore");
  }
  if (countLine(gitignorePath, ".agentsmd") !== 1) {
    throw new Error("Non-idempotent .agentsmd entry in generated .gitignore");
  }

  const repoAgentsContent = readFileSync(path.join(repoRoot, "AGENTS.md"), "utf8");
  const repoNotesContent = readFileSync(path.join(repoRoot, "AGENT_NOTES.md"), "utf8");
  const expectedGlobalNotesPath = `${workspaceRoot}${path.sep}AGENT_NOTES_GLOBAL.md`;
  if (!repoAgentsContent.includes(expectedGlobalNotesPath)) {
    throw new Error("Generated repo AGENTS.md does not interpolate workspace path.");
  }
  if (!repoNotesContent.includes(expectedGlobalNotesPath)) {
    throw new Error("Generated repo AGENT_NOTES.md does not interpolate workspace path.");
  }

  mkdirSync(path.join(repoRoot, "sub"), { recursive: true });
  writeFileSync(path.join(repoRoot, "sub", "AGENT_NOTES_EXTRA.md"), "nested note\n", "utf8");

  if (runGit(["-C", repoRoot, "init", "-q"]).status !== 0) {
    throw new Error("Failed to initialize temporary git repository for validation.");
  }
  runGit(["-C", repoRoot, "config", "user.email", "validate@example.com"]);
  runGit(["-C", repoRoot, "config", "user.name", "validate"]);

  if (runGit(["-C", repoRoot, "add", "-f", "AGENTS.md", "AGENT_NOTES.md", "sub/AGENT_NOTES_EXTRA.md"]).status !== 0) {
    throw new Error("Failed to add tracked validation fixtures.");
  }
  if (runGit(["-C", repoRoot, "commit", "-qm", "seed tracked notes"]).status !== 0) {
    throw new Error("Failed to commit tracked validation fixtures.");
  }

  applyRepoPolicy(workspaceRoot, repoRoot);

  if (isTracked(repoRoot, "AGENT_NOTES.md")) {
    throw new Error("AGENT_NOTES.md should be untracked after policy application.");
  }
  if (isTracked(repoRoot, "sub/AGENT_NOTES_EXTRA.md")) {
    throw new Error("Nested AGENT_NOTES file should be untracked after policy application.");
  }
  if (!isTracked(repoRoot, "AGENTS.md")) {
    throw new Error("AGENTS.md should remain tracked for Codex review guidance.");
  }

  console.log("setup consistency checks passed");
}

function main(): void {
  const { command, flags } = parseArgs(Bun.argv.slice(2));
  if (!command || flags.help === true || command === "help") {
    usage();
    return;
  }

  if (command === "apply") {
    const workspaceRoot = mustFlag(flags, "workspace-root");
    const repoRoot = mustFlag(flags, "repo-root");
    applyRepoPolicy(workspaceRoot, repoRoot);
    return;
  }

  if (command === "workspace-init") {
    const workspaceRoot = mustFlag(flags, "workspace-root");
    workspaceInit(workspaceRoot);
    return;
  }

  if (command === "setup") {
    const workspaceRoot = mustFlag(flags, "workspace-root");
    const repoRoot = mustFlag(flags, "repo-root");
    workspaceInit(workspaceRoot);
    applyRepoPolicy(workspaceRoot, repoRoot);
    return;
  }

  if (command === "validate") {
    validateSetupConsistency();
    return;
  }

  throw new Error(`Unknown command: ${command}`);
}

try {
  main();
} catch (error) {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Error: ${message}`);
  usage();
  process.exit(1);
}
