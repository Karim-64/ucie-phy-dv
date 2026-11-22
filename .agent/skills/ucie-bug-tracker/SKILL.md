---
name: ucie-bug-tracker
description: Workflow and strict formatting rules for filing UCIe PHY RTL/DV bug reports on GitHub via the GitHub MCP server (`github-mcp-server`). Use when the user asks to file, log, or draft a bug report or GitHub issue for the UCIe PHY repository.
---

# UCIe Bug Tracker

Follow these strict rules whenever filing a bug report in `Karim-64/ucie-phy-dv` using `github-mcp-server`.

## Rules

1. **One bug = one issue**
   - If the user's input describes multiple distinct bugs or failures, split them into separate issues—one per bug.
   - Do not bundle unrelated failures into a single issue.

2. **Check for duplicates first**
   - Before drafting or filing, search existing open issues using `list_issues` (`owner: "Karim-64"`, `repo: "ucie-phy-dv"`, `state: "OPEN"`) and/or `search_issues` (`owner: "Karim-64"`, `repo: "ucie-phy-dv"`, `query: "<keywords>"`).
   - If a matching or related open issue already exists, report it to the user instead of creating a duplicate.

3. **Title format**
   - Format: `[BLOCK] Concise summary`
   - Must be **under 72 characters** total.
   - Valid `BLOCK` tags: `SBTX`, `SBRX`, `LTSM`, `CREDITS`, `ADAPTER`, `OTHER`.
   - Example: `[SBTX] Priority encoder drops simultaneous request on lane 2`

4. **Required issue body structure**
   Every issue body must include the following sections:

   ```markdown
   ### Module
   <SBTX | SBRX | LTSM | Credits | Adapter | Other>

   ### Summary
   <Concise description of the bug and affected signals/transactions.>

   ### Expected Behavior
   <Expected behavior per the UCIe specification or thesis/design doc, with section references if known.>

   ### Actual Behavior
   <Observed behavior in simulation/RTL, including UVM_ERROR or SVA assertion messages.>

   ### Reproduction
   - **Test name:** `<test_name>`
   - **Seed:** `<seed>`
   - **Branch / Commit:** `<branch_or_commit_sha>`
   - **Failing Packets / Logs:**
     ```text
     <paste failing packets, hex dumps, or relevant log lines>
     ```

   ### Waveform
   <!-- Drag and drop waveform screenshots here after the issue is created -->
   ```

   - If any reproduction detail (such as seed or commit hash) was not provided, ask the user or explicitly mark it as `TBD` in the draft so they can confirm before filing.

5. **Mandatory approval before calling `issue_write`**
   - **NEVER** call `issue_write` without explicit user approval.
   - Always present the complete drafted issue to the user first:
     - **Title** (and character count)
     - **Labels** (e.g., block: `sbtx`/`sbrx`/`ltsm`/`credits`/`adapter`, type: `rtl-bug`/`tb-bug`/`spec-ambiguity`, and any applicable severity/status)
     - **Assignee(s)** (or `Unassigned` if none specified)
     - **Body** (full rendered markdown)
   - Wait for the user to approve or request edits before calling `issue_write` (`method: "create"`).

6. **Return the clickable issue URL**
   - Immediately after `issue_write` succeeds, return the clickable issue URL (e.g., `https://github.com/Karim-64/ucie-phy-dv/issues/<number>`) so the user can open it and drag-and-drop waveform screenshots directly into the `### Waveform` section.
