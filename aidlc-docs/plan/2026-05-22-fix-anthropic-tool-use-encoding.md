# Fix Anthropic multi-round tool-use encoding

**Issue:** #2  
**Explore brief:** https://github.com/tienan92it/mindb/pull/1 (digest: `aidlc-docs/explore/2026-05-22-daily-digest.md` §1)

## Summary

`AnthropicProvider.chat` builds outbound Messages API payloads incorrectly: assistant turns drop `tool_use` blocks (text-only), and every `tool` role message uses a hardcoded `tool_use_id: 'tool_result'`. Round 2+ of the agent loop therefore cannot correlate tool results with the assistant’s prior tool calls, causing 400s or wrong tool routing. Fix by mirroring the OpenAI path: encode `ChatMessage.toolCalls` as `tool_use` blocks, bind `tool_result.tool_use_id` to `ChatMessage.toolCallId`, and batch parallel tool results into one `user` message per Anthropic’s contract. No orchestrator or UI changes required — `AiAgentOrchestrator` already populates `toolCalls` / `toolCallId` on `ChatMessage`.

## Files to touch

| File | Change |
|------|--------|
| `lib/data/llm/anthropic_messages.dart` | **New.** `encodeAnthropicMessages(List<ChatMessage>)` + helpers (coalesce tool results, build assistant content blocks). |
| `lib/data/llm/anthropic_provider.dart` | Replace inline `conversation` map with `encodeAnthropicMessages`; keep response parsing as-is. |
| `test/anthropic_messages_test.dart` | **New.** Golden-style unit tests for encoded payload shapes (no HTTP). |

**Out of scope:** `ChatMessage` model (fields already exist), `AiAgentOrchestrator`, `SessionContextBuilder`, streaming, new deps.

## Approach

### 1. Extract encoder (pattern: `openai_compatible_chat.dart`)

Add `encodeAnthropicMessages` that walks `messages` (skip `system` — still joined for top-level `system` string in provider).

| `ChatMessage` | Anthropic shape |
|---------------|-----------------|
| `user` | `{ role: 'user', content: [{ type: 'text', text }] }` — omit empty text block if needed later; v1 keep text block. |
| `assistant` + `toolCalls` | `{ role: 'assistant', content: [ text?, tool_use×N ] }` where each `tool_use` is `{ type, id, name, input }` and `input` is `call.arguments` (Map, not JSON string). |
| `assistant` (text only) | Single `text` block as today. |
| `tool` | Contribute to **one** pending `user` message: `{ type: 'tool_result', tool_use_id: message.toolCallId ?? 'tool', content: message.content }` (string). |

### 2. Coalesce consecutive `tool` messages

`AiAgentOrchestrator` appends one `ChatMessage(role: 'tool', …)` per tool call in a round. Anthropic requires **all** `tool_result` blocks for that assistant turn in **one** `user` message. In the encoder:

- When seeing `role == 'tool'`, append to a buffer instead of emitting immediately.
- Flush buffer as a single `{ role: 'user', content: [ …tool_results ] }` when the next non-tool message arrives or at end of list.

This avoids `invalid_request_error` for parallel `get_schema` + `execute_sql` in one round.

### 3. Wire provider

In `AnthropicProvider.chat`:

```dart
'messages': encodeAnthropicMessages(
  messages.where((m) => m.role != 'system').toList(),
),
```

Keep `system` extraction and tools payload unchanged. Response parsing (lines 84–111) already maps `tool_use` → `LlmToolCall` with real ids.

### 4. Validation checklist (dev)

- Single tool round: schema-only prompt encodes one `tool_use` + one `tool_result` with matching ids.
- Multi-round: after first round, second request payload includes prior assistant `tool_use` blocks and batched `tool_result` with correct ids (inspect via unit test fixtures, not live API in CI).
- Parallel tools in one round: two `tool` ChatMessages → one Anthropic `user` message with two `tool_result` blocks.

## Tests

- **Unit:** `test/anthropic_messages_test.dart`
  - Assistant with `toolCalls` → content contains `tool_use` entries with `id`, `name`, `input`.
  - Tool message uses `toolCallId` in `tool_use_id` (not `'tool_result'`).
  - Two consecutive `tool` messages → single `user` message with two `tool_result` blocks.
  - User + assistant + tool sequence alternation matches Anthropic docs (no back-to-back `user` except coalesced tool batch).
- **Regression:** Encode a 3-message fixture simulating orchestrator history after round 1 (user prompt, assistant+tools, tool result) and assert round-2-bound payload includes assistant `tool_use` block.
- **Manual (QA smoke #4):** Anthropic provider, connected DB, prompt requiring ≥2 tool rounds (e.g. “list tables then count rows in the largest”).

## Risks

- **Parallel tool batching:** Missing coalesce causes 400 `tool_use ids were not found in tool_result blocks` when Claude returns multiple `tool_use` in one turn.
- **Empty assistant text:** If `content` is empty but `toolCalls` present, send assistant message with only `tool_use` blocks (no spurious empty `text` block required; add `text` only when `message.content.trim().isNotEmpty`).
- **Id fallback:** `toolCallId ?? 'tool'` matches OpenAI encoder fallback; orchestrator always sets real ids from API — fallback only for tests.
- **Session history:** `SessionContextBuilder.buildLlmHistory` does not persist tool calls (text-only turns). Out of scope for this PR; multi-round within a single `run()` is the fix target.

## Rollback

Revert the PR. Anthropic path returns to broken multi-round behavior; OpenAI/Kimi unchanged. No migrations or persisted format changes.

## Ready for dev

- [x] Single-PR scope confirmed (encoder + provider wire + tests)
- [x] No new infra / deps
- [x] Matches existing patterns (`encodeOpenAiMessages` in `openai_compatible_chat.dart`)
