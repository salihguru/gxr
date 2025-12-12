#!/usr/bin/env node

import { build } from "./build";
import { watch } from "./watch";

const args = process.argv.slice(2);
const command = args[0];

function printHelp() {
  console.log(`
GXR - Go x React SSR Framework

Usage:
  npx gxr <command> [options]

Commands:
  build     Build client components for hydration
  watch     Watch mode for development
  help      Show this help message

Options:
  --components <dir>   Components directory (default: ./client/components)
  --output <dir>       Output directory (default: ./public)

Examples:
  npx gxr build
  npx gxr build --components ./src/components --output ./dist
  npx gxr watch
`);
}

function parseArgs(args: string[]): Record<string, string> {
  const options: Record<string, string> = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i].startsWith("--") && args[i + 1]) {
      options[args[i].slice(2)] = args[i + 1];
      i++;
    }
  }
  return options;
}

async function main() {
  const options = parseArgs(args);

  switch (command) {
    case "build":
      await build({
        componentsDir: options.components || "./client/components",
        outputDir: options.output || "./public",
      });
      break;

    case "watch":
      await watch({
        componentsDir: options.components || "./client/components",
        outputDir: options.output || "./public",
      });
      break;

    case "help":
    case "--help":
    case "-h":
      printHelp();
      break;

    default:
      if (command) {
        console.error(`Unknown command: ${command}`);
      }
      printHelp();
      process.exit(command ? 1 : 0);
  }
}

main().catch((err) => {
  console.error("Error:", err.message);
  process.exit(1);
});
