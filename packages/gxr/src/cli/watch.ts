import * as fs from "fs";
import { build, BuildOptions } from "./build";

/**
 * Watch for changes and rebuild
 */
export async function watch(options: BuildOptions): Promise<void> {
  const { componentsDir } = options;

  console.log("👀 Watching for changes...");
  console.log(`   Components: ${componentsDir}`);
  console.log("");

  // Initial build
  await build(options);

  // Watch for changes
  let debounceTimer: NodeJS.Timeout | null = null;

  const rebuild = () => {
    if (debounceTimer) {
      clearTimeout(debounceTimer);
    }
    debounceTimer = setTimeout(async () => {
      console.log("\n🔄 Rebuilding...\n");
      try {
        await build(options);
      } catch (err) {
        console.error("Build failed:", err);
      }
    }, 100);
  };

  // Watch components directory
  if (fs.existsSync(componentsDir)) {
    fs.watch(componentsDir, { recursive: true }, (eventType, filename) => {
      if (filename && (filename.endsWith(".tsx") || filename.endsWith(".ts"))) {
        console.log(`\n📝 Changed: ${filename}`);
        rebuild();
      }
    });
  }

  // Keep process running
  console.log("\nPress Ctrl+C to stop watching.\n");
}
