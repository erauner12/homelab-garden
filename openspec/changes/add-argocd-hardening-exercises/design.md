## Context

The existing GitOps reconciliation and hcloud self-heal specs already prove baseline sync/health and drift correction. This change should not re-spec those behaviors as new work. It uses them as prerequisites, then adds focused hardening exercises that show how ArgoCD limits blast radius and rejects unsafe desired state.

## Goals / Non-Goals

**Goals:**
- Demonstrate prune behavior only against lab-owned disposable resources.
- Demonstrate AppProject restrictions blocking an unsafe source, destination, namespace, or resource kind.
- Demonstrate sync option safety for lab-scoped examples, such as disabled prune by default or explicit server-side apply behavior where relevant.
- Produce blast-radius reporting before any bounded destructive or denial exercise.
- Support local and hcloud lab exercises with target guards.

**Non-Goals:**
- Do not reimplement or restate baseline sync/self-heal validation as the main new exercise.
- Do not enable broad prune on shared or real homelab resources.
- Do not import the real homelab AppProject model wholesale.
- Do not make ArgoCD hardening part of `make check` or local validation.

## Decisions

- Require existing sync/self-heal evidence before running hardening scenarios so failures are not confused with baseline reconciliation issues.
- Use dedicated lab Applications or fixtures for prune tests so deleting an object proves behavior without risking core platform resources.
- Prefer negative AppProject tests that are safe and explanatory, such as denied namespace or denied repository, rather than broad production policy copies.
- Add blast-radius reporting that lists Applications, namespaces, resources, sync options, and prune candidates before the exercise proceeds.
- Require hcloud target guard before running hardening exercises in `hcloud-lab`.

## Risks / Trade-offs

- Prune tests can be destructive → constrain them to disposable lab resources and require blast-radius reporting.
- Sync option examples can become too broad → keep them tied to explicit safety behavior and lab-scoped fixtures.
- Hcloud exercises can mutate cloud-hosted workloads → require target guard and isolated resources.
