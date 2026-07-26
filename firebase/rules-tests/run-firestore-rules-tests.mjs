import { spawnSync } from "node:child_process";

const requiredFirebaseToolsVersion = "15.13.0";
const versionResult = spawnSync("firebase", ["--version"], {
  encoding: "utf8",
});

if (versionResult.error?.code === "ENOENT") {
  console.error(
    `Firebase CLI ${requiredFirebaseToolsVersion} is required. `
      + `Install it with: npm install --global firebase-tools@${requiredFirebaseToolsVersion}`,
  );
  process.exit(1);
}

if (versionResult.status !== 0) {
  console.error(versionResult.stderr.trim());
  process.exit(versionResult.status ?? 1);
}

const installedFirebaseToolsVersion = versionResult.stdout.trim();

if (installedFirebaseToolsVersion !== requiredFirebaseToolsVersion) {
  console.error(
    `Firebase CLI ${requiredFirebaseToolsVersion} is required, `
      + `but ${installedFirebaseToolsVersion} is installed. `
      + `Install the required version with: npm install --global `
      + `firebase-tools@${requiredFirebaseToolsVersion}`,
  );
  process.exit(1);
}

const testResult = spawnSync(
  "firebase",
  [
    "emulators:exec",
    "--config",
    "../../firebase.json",
    "--project",
    "demo-franalonso-rules",
    "--only",
    "firestore",
    "node --test firestore.rules.test.mjs",
  ],
  { stdio: "inherit" },
);

if (testResult.error) {
  console.error(testResult.error.message);
  process.exit(1);
}

process.exit(testResult.status ?? 1);
