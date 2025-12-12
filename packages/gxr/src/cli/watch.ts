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

  // Watch for changes with debouncing and build lock to prevent race conditions
  let debounceTimer: NodeJS.Timeout | null = null;
  let isBuildInProgress = false;
  let pendingRebuild = false;

  const rebuild = () => {
    if (debounceTimer) {
      clearTimeout(debounceTimer);
    }
    
    // Use a longer debounce (300ms) to handle rapid file saves and editor auto-save
    debounceTimer = setTimeout(async () => {
      // If a build is already running, mark that we need another one after it completes
      if (isBuildInProgress) {
        pendingRebuild = true;
        return;
      }

      isBuildInProgress = true;
      console.log("\n🔄 Rebuilding...\n");
      
      try {
        await build(options);
      } catch (err) {
        // Error is already logged by build(), just acknowledge the failure
        console.error("Build failed. Waiting for changes...");
      } finally {
        isBuildInProgress = false;
        
        // If changes occurred during build, trigger another rebuild
        if (pendingRebuild) {
          pendingRebuild = false;
          console.log("📝 Changes detected during build, rebuilding...");
          rebuild();
        }
      }
    }, 300);
  };

  // Watch components directory
  if (fs.existsSync(componentsDir)) {
    fs.watch(componentsDir, { recursive: true }, (eventType, filename) => {
      if (filename && (filename.endsWith(".tsx") || filename.endsWith(".ts"))) {
        console.log(`\n📝 Changed: ${filename}`);
        rebuild();
      }
    });
  } else {
    console.warn(`⚠️  Components directory not found: ${componentsDir}`);
    console.warn("   Create the directory and add components to start watching.");
  }

  // Keep process running
  console.log("\nPress Ctrl+C to stop watching.\n");
}
