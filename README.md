# CKA Practice (Simple Edition)

Straightforward CKA practice labs derived from the CKA-PREP playlist. Every question lives in its own folder with three bash files:

- `LabSetUp.bash` � copy/paste into Killercoda (or any Kubernetes cluster) to prep the environment.
- `Questions.bash` � the scenario text plus the YouTube link for the walkthrough.
- `SolutionNotes.bash` � a step-by-step solution when you need a hint.

## How to Use
1. Launch the CKA Killercoda playground or your own cluster.
2. Clone this repo inside the environment.
3. Run the script — no `chmod` required, the executable bit is tracked by git.

**Interactive mode** (pick from a numbered menu, with keyword filtering):
```bash
./scripts/run-question.sh
```

**CLI mode** (jump straight to a question by number or name):
```bash
./scripts/run-question.sh Question-01
./scripts/run-question.sh "Question-8 CNI & Network Policy"
```

> The script auto-detects the repo root, so it works from any directory — you don't need to `cd` first.

4. Work through the task, then consult `SolutionNotes.bash` if you need help.

## Available Questions
| Question | Topic | Video |
|----------|-------|-------|
| Question-01 | Install Argo CD using Helm without CRDs | https://youtu.be/8GzJ-x9ffE0 |

More questions can be added by copying the template folder and dropping in the three bash files from the original collection.
