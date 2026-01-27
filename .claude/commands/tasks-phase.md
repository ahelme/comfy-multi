---
description: Execute a Phase of an Implementation File using Claude Code Tasks and multi-agent orchestration
argument-hint: <phase-number> in <implementation-file>
allowed-tools: Bash(git:*), Bash(gh:*), Read, Write, Edit, Grep, Glob, Task
---

`Usage: /tasks-phase $ARGUMENTS`

# Execute Phase $ARGUMENTS by creating a Task List and orchestrating Two SubAgents per Task

## Examples:

`/tasks-plan 13 in implementation-backup-restore.md` → Create a Task List and create/assign two subagents per Task to execute Phase 13 from the backup-restore implementation file

`/tasks-plan 1 in implementation-api.md` → Create a Task List and create/assign two subagents per Task to execute Phase 1 from the API implementation file


## Purpose

Execute an Implementation **Phase** using Claude Code’s **Tasks** feature (added January 24, 2026). 

Tasks enable persistent, dependency-tracked work items that coordinate across multiple sessions and subagents via file-system storage (`~/.claude/tasks`).



## Core Definitions

| Term                    | Definition                                                                                                                                                                                                                                                                                                                                                |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Project**             | This codebase + work defined in project docs e.g. `@CLAUDE.md`, `@README.md`, and `implementation*.md` files                                                                                                                                                                                                                                              |
| **Implementation File** | A file containing work to be implemented e.g.  `implementation-*.md` file                                                                                                                                                                                                                                                                                 |
| **Milestone**           | The set of work grouped in one `implementation-*.md` file                                                                                                                                                                                                                                                                                                 |
| **Phase**               | A single numbered phase within one Milestone’s `implementation-*.md` file                                                                                                                                                                                                                                                                                 |
| **Plan**                | A Claude Code feature to plan specific work for a set of features/fixes (not necessarily attached to a Phase or Milestone)                                                                                                                                                                                                                                |
| **Task-List**           | Created to complete tasks (e.g. within one Plan or Phase)  - uses NEW Claude Code ‘Tasks’ feature, includes dependencies, see: [https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/system-prompts/agent-prompt-task-tool.md](https://github.com/Piebald-AI/claude-code-system-prompts/blob/main/system-prompts/agent-prompt-task-tool.md) |
| **Issue**               | A GitHub issue accessed via `gh` CLI                                                                                                                                                                                                                                                                                                                      |



## Environment Setup

```bash
# All sessions working on this Plan share the same Task List
CLAUDE_CODE_TASK_LIST_ID=<new-task-list-ID>
```

This environment variable enables:

- Multiple sessions/subagents collaborating on the same Task List within their own git worktree/branch
- Real-time broadcast of Task updates to all connected sessions
- Persistent storage in:
	```bash
	`~/.claude/tasks/<new-task-list-ID>/`
	```


---- 

## Orchestration Workflow

### Workflow Step 0a: Task List Initialization - Idempotent

```bash
# 1. Ensure base tasks directory exists (no-op if already present)
mkdir -p ~/.claude/tasks

# 2. Generate new Task List ID and date
export CLAUDE_CODE_TASK_LIST_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
export TASK_DATE=$(date +%Y-%m-%d)

# 3. Create directory for this new task list
mkdir -p ~/.claude/tasks/$CLAUDE_CODE_TASK_LIST_ID

# 4. Handle .env.claude - create if missing, update if exists
if [[ ! -f .env.claude ]]; then
    # Create new .env.claude
    echo "CLAUDE_CODE_TASK_LIST_ID=$CLAUDE_CODE_TASK_LIST_ID" > .env.claude
    echo "TASK_DATE=$TASK_DATE" >> .env.claude
else
    # Update or append CLAUDE_CODE_TASK_LIST_ID
    if grep -q '^CLAUDE_CODE_TASK_LIST_ID=' .env.claude; then
        sed -i.bak "s/^CLAUDE_CODE_TASK_LIST_ID=.*/CLAUDE_CODE_TASK_LIST_ID=$CLAUDE_CODE_TASK_LIST_ID/" .env.claude
    else
        echo "CLAUDE_CODE_TASK_LIST_ID=$CLAUDE_CODE_TASK_LIST_ID" >> .env.claude
    fi

    # Update or append TASK_DATE
    if grep -q '^TASK_DATE=' .env.claude; then
        sed -i.bak "s/^TASK_DATE=.*/TASK_DATE=$TASK_DATE/" .env.claude
    else
        echo "TASK_DATE=$TASK_DATE" >> .env.claude
    fi

    # Clean up sed backup file
    rm -f .env.claude.bak
fi

echo "Initialized task list: $CLAUDE_CODE_TASK_LIST_ID"
echo "Task date: $TASK_DATE"
```

### Workflow Step 1a: Phase Analysis & Task Creation

1. **Read Phase**: `$ARGUMENTS`
2. **Analyze dependencies** between work items
3. **Create Tasks in `$CLAUDE_CODE_TASK_LIST_ID`** using `TaskCreate` tool with:
	   A) Clear title and description
	   B) Dependency metadata linking blocked/blocking tasks
	   C) Appropriate priority ordering
4. **Analyse relevant gh issues** associated with each Task:
	   A) Search for relevant gh issues using gh cli
```bash
   RELATED=$(gh issue list --search "<keywords-from-task>" --json number,title --jq '.[] | "- #\(.number): \(.title)"' | head -5)
```
   B) Add relevant gh issues to each task using `TaskUpdate` tool
   e.g. append `(Related issues: $RELATED)`

### Workflow Step 1b: Environment Propagation  

Before spawning subagents, ensure the Task List ID is available:
```bash
# Source environment for current session
source .env.claude

# Verify Task List ID is set
if [[ -z "$CLAUDE_CODE_TASK_LIST_ID" ]]; then
    echo "Error: CLAUDE_CODE_TASK_LIST_ID not set. Run Task 0a first."
    exit 1
fi

echo "Spawning subagents for Task List: $CLAUDE_CODE_TASK_LIST_ID"
```

### Workflow Step  2: Subagent Deployment Loop

For each Task `#Z`:
- spawn **two subagents**: as described in Steps 2A and 2B below 
Then repeat Subagent Deployment for next Task `#Z+1` as described in Step 2C below

#### Workflow Step 2A. `subagent-task-#Z` (Implementation Agent)

##### Core Context to provide Implementation Agent (replace `#Z` with the next Task on the TaskList):
---
You are a Senior Developer working on Task `#Z` from TaskList: `$CLAUDE_CODE_TASK_LIST_ID`
  
    1.  READ YOUR CORE CONTEXT (read and action these first):
- `@CLAUDE.md`
	- `@README.md`  
	- `./.claude/CLAUDE-CONTEXT-ABOUT-US.md`
	- `./.claude/CLAUDE-AGENT-CONTEXT.md`

2. NOTE TODAY'S DATE: `$TASK_DATE`

3. READ YOUR TASK: `#Z` on TaskList: `$CLAUDE_CODE_TASK_LIST_ID`

4. READ (IF ANY) RELATED GITHUB ISSUES ASSOCIATED WITH YOUR TASK: e.g.
```bash
Related issues: 
- #42: Add authentication middleware
```

5. YOUR JOB (INSTRUCTIONS TO FOLLOW): Make code-changes required to complete Task `#Z`
---
##### Instructions to Provide Implementation Agent (replace `#Z` with the next Task on the TaskList):
---
1. **Create git worktree and branch** named: `subagent-task-#Z`
```bash
git worktree add ../worktree-task-#Z -b subagent-task-#Z
cd ../worktree-task-#Z
```
2. **Create a NEW GitHub issue** for your work on this task - with references to related issues:
```bash
gh issue create \
  --title "subagent-task-#Z: <short-description>" \
  --body "## Description
<task description> 
## Related Issues
- Relates to #
- Relates to #

## Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2"
```
3. **Development cycle:**
	   A) Develop for maintainability
	   B) Use latest stable libraries (verify via web search + TODAY’s DATE)
	   C) Follow best practices
	   D) Create/run tests in `tests/` directory
	   E) Note bugs in GitHub issue comments
	   F) Iterate until tests pass
4. **On new work discovered create a new Task:** 
	   - Before creating a new task: List the new task's dependencies
	   - Verify no task in the dependency chain depends back on the new task
	   - If circular dependency detected, flag in GitHub issue and request user guidance
	   - Only then create new Task in TaskList with dependencies
5. **On dependency updates:** Update relevant Tasks with concise pointers to files (no code blocks)
6. **Code Completion steps:**
```bash
# Commit and push
git add -A && git commit -m "feat(task-#Z): <description>"
git push -u origin subagent-task-#Z

# Create PR
gh pr create --title "Task #Z: <description>" --body "Closes #<issue-number>"
```
7. **Documentation updates:**
	A) Prepare list of docs & comments to update:
	 i) READ IN FULL & Review `@CLAUDE.md`, `@README.md`, `docs/admin-guide.md`, `user-guide.md`, other index/overview docs 
	  ii) Scan `docs/` folder for other relevant docs to update 
	  iii) Grep codebase for other docs and comments needing updates
	B) Create ToDo list of files to update 
	C) Update each file with concise yet comprehensive text
	D) Do not write redundant docs - use pointers to other docs only
	E) Do not include code blocks: summarize functionality
8. **Update Github Issue:**
```bash
gh issue comment <issue-number> --body "Task #Z complete. PR ready for review."
gh issue edit <issue-number> --add-label "ready-for-review"
```
   **Important:** Do NOT close the issue!
---

#### Workflow Step 2B. `code-reviewer-task-#Z` (Review Agent)

##### Core Context to provide Code Reviewer Agent (replace `#Z` with the next Task on the TaskList):
---
You are a Code Review Expert reviewing code created by a previous sub-agent working on Task `#Z` from TaskList: `$CLAUDE_CODE_TASK_LIST_ID`
  
    1.  READ YOUR CORE CONTEXT (read and action these first):
- `@CLAUDE.md`
	- `@README.md`  
	- `./.claude/CLAUDE-CONTEXT-ABOUT-US.md`
	- `./.claude/CLAUDE-AGENT-CONTEXT.md`

2. NOTE TODAY'S DATE: `$TASK_DATE`

3. READ THE RELEVANT SUBAGENT’S TASK: `#Z` on TaskList: `$CLAUDE_CODE_TASK_LIST_ID`

4. READ GITHUB ISSUE ASSOCIATED WITH THIS TASK: e.g.
```bash
IMPL_ISSUE=$(gh issue list --search "subagent-task-#Z" --json number --jq '.[0].number')
gh issue view $IMPL_ISSUE --comments
```

5. YOUR JOB (INSTRUCTIONS TO FOLLOW): Review the code created previously for Task `#Z` 
---
##### Instructions to Provide Code Reviewer Agent (replace `#Z` with the next Task on the TaskList):
---
1. **NEVER FIX CODE OR WRITE NEW CODE**: YOU ARE A **CODE REVIEWER** ONLY  

2. **Wait for review signal:**
```bash
# Poll until ready-for-review label appears
while ! gh issue view $IMPL_ISSUE --json labels -q '.labels[].name' | grep -q "ready-for-review"; do
  sleep 60
done
```

3. **Checkout the work:**
```bash
cd ../worktree-task-#Z  # or: git worktree add if needed
```

4. **Review code changes** in relation to `$IMPL_ISSUE`
```
git diff main...subagent-task-#Z
```

5. **Evaluate against criteria:**  

```
   |#|Criterion                     |Check                                          |
   |-|------------------------------|-----------------------------------------------|
   |1|Success criteria met?         |Compare against issue body                     |
   |2|Latest stable libraries?      |**Web search TODAY’S DATE** (not training data)|
   |3|Clear, logical implementation?|Code review                                    |
   |4|Duplicated existing functions?|**Search codebase**                            |
   |5|Spaghetti code or tech debt?  |Architecture review                            |
   |6|Best practices followed?      |Standards check                                |
   |7|Tests comprehensive?          |Create/run additional tests if needed          |
```

 6.  **Post review comment:**  

```bash
gh issue comment $IMPL_ISSUE --body "## Code Review - Task #Z

### Criteria Assessment
1. Success criteria: ✅/❌ <notes>
2. Library versions: ✅/❌ <notes>
3. Code clarity: ✅/❌ <notes>
4. No duplication: ✅/❌ <notes>
5. No tech debt: ✅/❌ <notes>
6. Best practices: ✅/❌ <notes>
7. Test coverage: ✅/❌ <notes>

### Test Results
<paste test output>

### Verdict
<PASS/FAIL with reasoning>"
```

7. **Update issue status:**

	A) If tests **PASS**:
	  
```bash
gh issue edit $IMPL_ISSUE --remove-label "ready-for-review" --add-label "ready-for-user-testing"
```

B) If tests **FAIL**:
  
```bash
gh issue edit $IMPL_ISSUE --remove-label "ready-for-review" --add-label "requires-fixes"
```
  
   **Important:** Do NOT close the issue!
---
#### Workflow Step  2C: Repeat Steps 2A & 2B for next Task (`#Z+1`)
Proceed to next Task `#Z+1` and repeat steps 2A & 2B until there are no more Tasks in the TaskList.

### Task Coordination Notes

- **Broadcasts:** When any session updates a Task, all sessions on this Task List receive the update automatically
- **Dependencies:** Tasks block/unblock based on metadata—check before starting work
- **Persistence:** All Task state survives session restarts (stored in `~/.claude/tasks/`)
- **Subagent limits:** Subagents cannot spawn other subagents—keep orchestration flat

### Communication Standards

All comments, docs, issues, and reports must be:

- **Concise** yet **comprehensive**
- **No fluff** or filler/boasting language
- **Pointers over redundancy ** in documentation (reference files, not duplicate content)

### Quick Reference

| Action - Tasks                 | Command - Tasks                                                      |
| ------------------------------ | -------------------------------------------------------------------- |
| View Task List                 | `/tasks` or use `TaskList` tool                                      |
| Create Task                    | `TaskCreate` with dependencies                                       |
| Update Task                    | `TaskUpdate` tool                                                    |
| Get Task Details               | `TaskGet` tool                                                       |
| Check Output of Task           | `TaskOutput` tool                                                    |
| Check if Task has been Updated | Task updates should broadcast automatically or use `TaskOutput` tool |
[Task Tool Commands]

| Action - Github (gh) issues (via cli) | Command - Github (gh) issues                 |
| ------------------------------------- | -------------------------------------------- |
| Check gh issue labels                 | `gh issue view <n> --json labels`            |
| Add gh issue label                    | `gh issue edit <n> --add-label "<label>"`    |
| Remove gh issue label                 | `gh issue edit <n> --remove-label "<label>"` |
[Github Issue Commands (gh cli)]


