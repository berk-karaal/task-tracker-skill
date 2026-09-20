import assert from "node:assert/strict"
import test from "node:test"
import { body, pathsFromInput, taskPath } from "../src/index.ts"

test("strips command frontmatter", () => {
  assert.equal(body("---\ndescription: Example\n---\n\nRun $ARGUMENTS."), "Run $ARGUMENTS.")
})

test("extracts direct and patch file paths", () => {
  assert.deepEqual(pathsFromInput({ filePath: ".tasks/demo/progress.md" }), [
    ".tasks/demo/progress.md",
  ])
  assert.deepEqual(
    pathsFromInput({ patchText: "*** Begin Patch\n*** Update File: .tasks/demo/task.md\n*** End Patch" }),
    [".tasks/demo/task.md"],
  )
})

test("resolves only task doc paths", () => {
  assert.equal(
    taskPath({ path: ".tasks/demo/progress.md" }, "/workspace/project"),
    "/workspace/project/.tasks/demo/progress.md",
  )
  assert.equal(taskPath({ path: "src/index.ts" }, "/workspace/project"), undefined)
})
