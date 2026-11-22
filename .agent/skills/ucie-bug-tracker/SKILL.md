---
name: ucie-bug-tracker
description: Workflow and strict formatting rules for filing UCIe PHY Bugs and Tasks/Block Status issues on GitHub via the GitHub MCP server (`github-mcp-server`) and tracking them on the UCIe GitHub Project. Use when the user asks to file, log, or draft a bug report, task, or block-status issue for `Karim-64/ucie-phy-dv`.
---

# UCIe Bug & Task Tracker

Follow these strict rules whenever filing a Bug or Task issue in `Karim-64/ucie-phy-dv` using `github-mcp-server`.

## 1. Issue Classification: Bugs vs. Tasks

Determine whether each item is a **Bug** or a **Task** and set the corresponding GitHub Issue Type (`type` parameter in `issue_write`) and labels:

| Kind | Issue Type (`type`) | Required Type Label | Additional Labels |
| :--- | :--- | :--- | :--- |
| **Bug** (RTL defect, TB defect, spec ambiguity) | `"Bug"` | One of `rtl-bug`, `tb-bug`, `spec-ambiguity` | Block label (`sbtx`, `sbrx`, `ltsm`, `credits`, `adapter`) |
| **Task** (TB bring-up, RTL feature, coverage closure, docs) | `"Task"` | `task` | Block label (`sbtx`, `sbrx`, `ltsm`, `credits`, `adapter`) if block-specific |

## 2. Core Filing Rules

1. **One item = one issue**
   - If the user's input describes multiple distinct bugs or tasks, split them into separate issues—one per item.
   - Do not bundle unrelated bugs or tasks into a single issue.

2. **Check for duplicates first**
   - Before drafting or filing, search existing open issues using `list_issues` (`owner: "Karim-64"`, `repo: "ucie-phy-dv"`, `state: "OPEN"`) and/or `search_issues` (`owner: "Karim-64"`, `repo: "ucie-phy-dv"`, `query: "<keywords>"`).
   - If a matching or related open issue already exists, report it to the user instead of creating a duplicate.

3. **Title format**
   - Format: `[BLOCK] Concise summary`
   - Must be **under 72 characters** total.
   - Valid `BLOCK` tags: `SBTX`, `SBRX`, `LTSM`, `CREDITS`, `ADAPTER`, `TOP`, `OTHER`.
   - Bug example: `[SBTX] Priority encoder drops simultaneous request on lane 2`
   - Task example: `[SBRX] Close functional coverage on pattern detector`

4. **Required issue body structure**

   ### For Bugs (`type: "Bug"`)
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

   ### For Tasks (`type: "Task"`)
   ```markdown
   ### Module
   <SBTX | SBRX | LTSM | Credits | Adapter | Top/Integration>

   ### Stage
   <VPlan | RTL Design | TB Bring-up | Regression | Coverage Closure>

   ### Summary / Goal
   <Concise description of the task, target sub-block behavior, or milestone.>

   ### Scope / Acceptance Criteria
   - [ ] <Deliverable or exit criterion 1>
   - [ ] <Deliverable or exit criterion 2>

   ### Dependencies / Blockers
   <None or related issues/PRs/spec dependencies>
   ```

5. **Populate the Project `Block/Module` field**
   - Whenever filing **either a Bug or a Task**, set the UCIe GitHub Project's **`Block/Module`** single-select field to the matching option:
     - `SBTX`, `SBRX`, `LTSM`, `Credits`, `Adapter`, or `Top/Integration`
   - If GitHub Projects tools are available in the session, add the created issue to the Project and update its `Block/Module` field (and `Start Date` / `Target Date` if provided).
   - If Projects tools are not available in `github-mcp-server`, include the target `Block/Module` value in the approval summary and instruct/provide the command to set it on the Project item.

6. **Mandatory approval before calling `issue_write`**
   - **NEVER** call `issue_write` without explicit user approval.
   - Always present the complete drafted issue to the user first:
     - **Title** (and character count)
     - **Issue Type** (`Bug` or `Task`)
     - **Labels**
     - **Project `Block/Module`** (and `Start Date` / `Target Date` if applicable)
     - **Assignee(s)** (or `Unassigned` if none specified)
     - **Body** (full rendered markdown)
   - Wait for the user to approve or request edits before calling `issue_write` (`method: "create"`).

7. **Return the clickable issue URL**
   - Immediately after `issue_write` succeeds, return the clickable issue URL (e.g., `https://github.com/Karim-64/ucie-phy-dv/issues/<number>`) so the user can open it (and drag-and-drop waveform screenshots for bugs or verify Project fields).
