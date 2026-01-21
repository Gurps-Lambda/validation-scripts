# NVMe Drive Validation – Practical Guide (With Commands)

## Purpose

This document defines a **practical, production-safe NVMe validation procedure** for:

- GPU nodes with multiple NVMe drives
- Pre-shipment drive validation
- Platform bring-up and sanity checks

### Goals
- Catch DOA or marginal drives
- Preserve drive endurance
- Produce deterministic, auditable results
- Avoid unnecessary test time

---

## Core Principles

1. **Baseline tests run serially (one drive at a time)**
2. **Stress tests run in parallel (all drives together)**
3. **Pre-shipment validation is short and non-destructive**
4. **Long tests validate the system, not the individual drive**
5. **Fail fast and stop on errors**

---

## Validation Phases Overview


Created README.md
