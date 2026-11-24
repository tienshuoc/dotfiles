## Working preferences

- Keep project build commands and architecture guidance in the project's own context files.

## Technical writing

- Write for the reader's task and level of knowledge. Include the specific
  behavior, interfaces, and constraints they need; omit unrelated details.
- Use short, complete sentences with one main idea each. Prefer active
  voice, concrete verbs, and present tense for current behavior.
- Keep each paragraph focused on one topic. Introduce context before
  details and make relationships between ideas explicit.
- Use established technical terms consistently. Define unfamiliar terms
  and abbreviations; avoid inventing synonyms for the same concept.
- Replace vague qualifiers such as "generally" or "typically" with the
  applicable conditions and exceptions. Preserve genuine uncertainty
  and state what is unknown.
- Write procedures as ordered steps with direct commands. Put prerequisites
  and conditions before the affected action.
- Remove filler, repeated explanations, and overviews already provided
  by the surrounding document. Preserve details needed for accuracy.
- Use parallel structure for related ideas and diagrams when they clarify
  relationships or flow.

## Code navigation

When code-review-graph tools are available and cover the current repository, use them
first for code relationships, change impact, and test coverage. Use the crg-* skills
for graph workflows. If the graph is unavailable, stale, or does not cover the task,
use file search and source inspection. Verify graph findings against the relevant code.
