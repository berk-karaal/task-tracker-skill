import { readFile } from "node:fs/promises"
import { spawn } from "node:child_process"
import { fileURLToPath } from "node:url"
import { isAbsolute, resolve } from "node:path"
import { Plugin, Skill } from "@opencode/plugin"

const commands = [
  ["init", "Initialize a new tracked task"],
  ["update", "Flush this session's work into task docs"],
  ["summary", "Summarize a task and prime context to resume it"],
  ["list", "List all tracked tasks and their status"],
  ["link", "Link an external task folder into this project"],
  ["unlink", "Detach a linked task without changing its remote docs"],
] as const

const root = new URL("../", import.meta.url)

function body(markdown: string) {
  return markdown.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, "").trim()
}

function pathsFromInput(input: unknown) {
  if (!input || typeof input !== "object") return []

  const value = input as Record<string, unknown>
  const paths = Object.entries(value)
    .filter(([key, item]) => /(?:file_?path|path)$/i.test(key) && typeof item === "string")
    .map(([, item]) => item as string)

  for (const item of Object.values(value)) {
    if (typeof item !== "string") continue
    for (const match of item.matchAll(/^\*\*\* (?:Add|Update|Delete) File: (.+)$/gm)) paths.push(match[1])
  }

  return paths
}

function taskPath(input: unknown, directory: string) {
  return pathsFromInput(input)
    .map((path) => (isAbsolute(path) ? path : resolve(directory, path)))
    .find((path) => path.split(/[\\/]/).includes(".tasks"))
}

function syncQmd(path: string) {
  const script = fileURLToPath(new URL("plugins/task-tracker/scripts/qmd-sync.sh", root))
  const child = spawn("bash", [script], {
    stdio: ["pipe", "ignore", "ignore"],
  })
  child.on("error", () => {})
  child.stdin.end(JSON.stringify({ file_path: path }))
}

export default Plugin.define({
  id: "task-tracker",
  async setup(ctx) {
    const commandFiles = await Promise.all(
      commands.map(async ([name, description]) => ({
        name,
        description,
        template: body(await readFile(new URL(`plugins/task-tracker/commands/${name}.md`, root), "utf8")),
      })),
    )

    const skillLocation = fileURLToPath(
      new URL("plugins/task-tracker/skills/task-tracking/SKILL.md", root),
    )
    const skillContent = body(await readFile(skillLocation, "utf8"))

    await ctx.skill.transform((editor) => {
      editor.add(Skill.Info.make({
        id: Skill.ID.make("task-tracking"),
        name: Skill.Name.make("Task Tracking"),
        description:
          "Conventions and auto-maintenance for persistent local task docs under .tasks/; use when tracking or resuming long-running work.",
        path: skillLocation as typeof ctx.location.directory,
        content: skillContent,
      }))
    })

    await ctx.command.transform((editor) => {
      for (const command of commandFiles) {
        editor.add({
          name: `task-tracker:${command.name}`,
          description: command.description,
          async execute({ sessionID, prompt, delivery }) {
            await ctx.session.prompt({
              ...prompt,
              sessionID,
              text: command.template.replaceAll("$ARGUMENTS", prompt.text),
              delivery,
            })
          },
        })
      }
    })

    await ctx.tool.hook("execute.after", (event) => {
      if (event.status !== "completed" || !["edit", "patch", "write"].includes(event.tool)) return
      const path = taskPath(event.input, ctx.location.directory)
      if (path) syncQmd(path)
    })
  },
})

export { body, pathsFromInput, taskPath }
