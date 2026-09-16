---
name: pr-description
description: Write a pull request description that is understood at a glance. Use when asked to write, draft, or improve a PR description or body, or when creating a PR with gh.
---

Write the PR description so a reviewer understands the change before reading a line of the diff. Visuals over word blocks: every section that can be a diagram, a tree, or a diff is one. Keep prose to the sentences the visuals cannot carry.

## First: does the repository have a PR template?

Check before writing anything: `.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/*.md`, or `docs/pull_request_template.md`. Also look at the last few merged PRs in the repository for the shape its reviewers expect.

- **A template exists: follow it.** Its sections, its headings, its order. The repository's reviewers read every PR in that shape and yours must not be the odd one out. Fit the material below *into* the template: the TL;DR note goes at the top of the first section, the diagrams and diff go under whichever section is about the change itself, the alternatives under any "why" or "context" section, the review directions under any "testing" or "review notes" section. Leave the template's own sections in place even where you add nothing.
- **A template exists but has no room for visuals or review directions:** put the parts that do not fit into a **comment on the PR** immediately after opening it (`gh pr comment`), so the description stays on-template and the reviewer still gets the diagrams and reading order.
- **No template:** use the structure below as the whole body.

## Structure

In this order, and nothing else:

## 1. TL;DR as a GitHub note

A `> [!NOTE]` callout at the very top, two or three sentences: what the PR does and the one thing a reviewer must know. GitHub renders it as a highlighted box.

```md
> [!NOTE]
> Moves session persistence from the request handler into a background writer.
> Requests no longer block on disk; the writer batches every 50 ms.
```

## 2. What it does, visually

One or more Mermaid diagrams showing the change. Pick the shape that matches the change:

- `sequenceDiagram` for a changed interaction between components
- `flowchart` for a changed decision path or data flow
- `stateDiagram-v2` for a changed lifecycle
- `classDiagram` or a tree for a changed structure

Show *before* and *after* when the contrast is the point; show only *after* when the old shape is obvious. Label participants with the real names from the code.

## 3. The relevant change, as a diff

The essential lines, as a diff block. Real code where it is short; pseudocode where real code would bury the point in detail. The reader should see the shape of the change, not its every line, so cut everything that is mechanical.

```diff
 handleRequest(req)
-  session.save()          # blocked on disk
+  writer.enqueue(session) # returns immediately
   respond(req)
```

## 4. Why this approach

A short paragraph: the reason for this design, then the alternatives that were considered and why each was not chosen. Alternatives as a list, one line each, so the reviewer can see the decision space without reading an essay.

## 5. How to review it

Directions for reading the diff in the right order: which file first, what to look at in it, what to check next. If control flow matters, give the call stack as a tree so the reviewer can follow it top-down:

```text
handleRequest
  writer.enqueue
    batch.push
  respond
writer.flush (timer, every 50 ms)
  store.writeAll
```

Name what you are unsure about, so review attention goes there first.

## Rules

- The repository's template wins over this structure, always.
- Everything in one body (or body plus one comment when the template forces it); no links to external docs for the core explanation.
- No filler sections. If a section has nothing to say, omit it.
- Use the project's own terminology and file names.
- When creating the PR, pass the body with `gh pr create --body-file`, not inline, so the Markdown survives the shell.
