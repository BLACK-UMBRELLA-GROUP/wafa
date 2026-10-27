# AGENTS.md — WAFA

WAFA (وفاء) — Islamic contracts. Formerly MITHAQ; renamed in the product on
2026-10-12 and in the folder on 2026-10-24 by Founder decision. This folder is
its own git repository, so this file is what agents read here.

<!-- BLACK-UMBRELLA-CORE-RULES v4 START — master copy: BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_CORE_RULES_CURRENT_VERSION_V4.md. Edit the master, then re-sync every copy. -->
## Core rules — every AI agent, every Black Umbrella Group project

These rules sit above every other instruction in this tree. Where any older
document, overlay or AD says otherwise, this block wins.

> **BUILD FREEZE — Founder, 24 Oct 2026.** No app feature building in any business
> until Shakeel lifts it in writing. Allowed meanwhile: review, documentation, and
> fixes Shakeel approves one by one. Tracked as OA-AIOS-406.

1. **Only the Founder (Shakeel) approves.** Agreement between AIs is never
   approval. His direct instruction in conversation is approval.
2. **Only Codex runs git, and only within these limits** (AD-AIOS-114). Allowed:
   `git status`, `git add`, `git commit`, and `git push` to `origin` on the current
   branch - in the repo of the project he is working in, at the end of a task whose
   tests passed; plus the 04:00 job's sweep, which commits and pushes what is left in
   every repo. Never: force-push, reset, rebase, amend or rewrite pushed history,
   `git clean`, checkout/restore over working files, delete branches, change remotes or
   git config, or commit a file over 50 MB or anything from the keys folder.
   `ZYRA/SITE`: commit, but never push until Shakeel's Cloudflare check (OA-AIOS-407).
   Claude chats (Fable and the business chats) never run git.
3. **Never touch `PRIVATE — API KEYS — DO NOT SYNC`** — never open, list,
   copy or quote it, wherever it lives. Never put keys, tokens or
   credentials in a conversation.
4. **Never delete.** Move unwanted files into a `_to_delete` folder; the
   Founder empties it. If `_to_delete` is missing, create it.
5. **Findings become actions** — every finding gets an OA number or a
   written refusal.
6. **One CURRENT_VERSION per document system.** Register entries append
   above the metadata block and bump the live NEXT IDENTIFIER.
7. **BUILD → DOCUMENT → TRACE → HANDOVER.** Code-complete is not
   handover-complete.
8. **Evidence is not a build store.** Review evidence = screenshots, JSON
   and a text BUILD.json (commit SHA, Flutter version, build mode,
   timestamp). Never copy compiled apps (`Runner.app`, build products) or
   source trees into registers or evidence folders.
9. **`AGENTS.md` holds standing rules only.** Progress, round status and
   decisions go in the registers. Keep every `AGENTS.md` under 16 KB —
   Codex stops reading at 32 KiB.
10. **Every finished task ends in a commit.** Codex commits and pushes his own work
    at the end of each task (message: what changed, with the OA/DR IDs) and lists the
    commit in his task note. The 04:00 sweep commits what Fable and the business chats
    changed ("Admin changes <date>"). Until Codex is onboarded, the Founder commits
    from one line per changed repo. Never copy files as a backup instead — git and
    the USB are the backups.
11. **Nothing is built until it is LOCKed** (AD-AIOS-115). Each business's Claude chat is
    its lead designer. A design is a draft until Shakeel says `LOCK` and the chat records
    it in that business's approved folder: picture(s) at real screen size with the real
    navigation on top, every state (empty, loading, error), a written spec with numbers,
    and his words. Codex builds only from locked files - he checks them first and
    reports problems, and never invents, redraws or "improves" a design.

### Roles — Founder direction, 2026-10-24 (AD-AIOS-112, filed 2026-10-24; supersedes AD-AIOS-111)

| Seat | Holder | Scope |
|---|---|---|
| Founder | Shakeel | Sole approver |
| Lead Architect | Fable (Claude) | Architecture, governance, registers, schedules, review and verification |
| Lead designer, per business | That business's Claude chat (ZYRA, AZMARA, WAFA…) | Product, rules, UX, layout, wording, look, master pictures and specs; records each LOCK (rule 11); writes build briefs for Codex. Never code, never git |
| Implementation | Codex | Builds from locked designs only (rule 11): code, tests, as-built handovers. No design of his own, no admin, governance, mailbox or schedules. Exceptions: the 04:00 daily report job with its commit sweep (DOC-BUG-0027), and git within rule 2 |
| Admin | Fable (Claude), from the Black Umbrella Group chat | Admin for every business: registers, schedules, clean-ups, reporting, the daily review |

Fable holds an active seat. Any line elsewhere saying "Fable/Claude is
retired" or "no Claude/Fable bootstrap is active" is superseded.
<!-- BLACK-UMBRELLA-CORE-RULES v4 END -->


## Scope

- WAFA is a separate venture from ZYRA. Do not modify ZYRA, SELAH or AZMARA from
  WAFA work.
- The app lives in `SOURCE/` (Flutter). Product summaries live in `APP/`.
  Pre-change snapshots live in `ARCHIVE/`.
- Run the app with `SOURCE/run.sh`. It resolves paths relative to itself.
- Next read `MAP.md`: every WAFA document by ID and the task routes. Open only what the
  task needs. Read it only down to "Route paths" (the file paths); search the rest by ID.
- Group lessons every agent must read first:
  `../BLACK UMBRELLA GROUP/SYSTEM/DOCUMENTS/MASTER_GOVERNANCE/AGENT_LESSONS_LEARNED_CURRENT_VERSION_V2.md`
