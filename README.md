# Azure Arc SQL License Enforcement (Policy + Automation)

## Overview

This repository demonstrates an **Azure-native pattern** for enforcing SQL Server licensing configuration for **SQL Server enabled by Azure Arc**, using a combination of:

- Azure Resource Graph (ARG)
- Automation (Runbook / Azure Function)
- Azure Policy with `DeployIfNotExists` (DINE)

The solution targets **Arc-enabled machines running SQL Server Standard edition** and ensures that the **SQL Server extension license type** is set to **`Paid`** (Azure Hybrid Benefit / SA), but **only when the machine explicitly opts in via a tag**.

The design intentionally avoids:
- extension-level policy evaluation (unsupported by Azure Policy),
- broad, subscription-wide enforcement,
- and unintended changes to non-SQL machines.

---

## What this solution does

At a high level:

1. **Discovery**
   - Azure Resource Graph is used to identify SQL Server instances with:
     - `edition == Standard`
     - running on Arc-enabled machines

2. **Opt-in via automation**
   - Automation (Runbook or Azure Function) tags the **Arc machine** when it is eligible:
     ```
     EnableLicenseChange = true
     ```
   - Tag name and value are configurable.

3. **Policy enforcement**
   - An Azure Policy with `DeployIfNotExists`:
     - evaluates **Arc machines**
     - checks for the presence of the SQL Server extension
     - gates enforcement based on the opt-in tag
     - remediates the SQL Server extension by setting:
       ```
       LicenseType = Paid
       ```

4. **Lifecycle behavior**
   - New machines are remediated automatically once tagged.
   - Existing machines require a one-time remediation task.
   - Drift is corrected on subsequent resource updates.

---

## Why machine-level tagging is used

Azure Policy **cannot evaluate extension tags or extension-level resources directly** due to alias limitations.

This solution therefore:
- evaluates **`Microsoft.HybridCompute/machines`**
- remediates **`Microsoft.HybridCompute/machines/extensions`**
- uses **machine-level tags** as the explicit opt-in signal

This aligns with Azure Policy’s supported **parent → child DINE model** and avoids silent non-evaluation.

---

## What this is NOT

- ❌ A fully hardened production solution
- ❌ A replacement for licensing compliance or legal guidance

## ⚠️ Disclaimer

> **This repository is provided for educational and demonstration purposes only.**

The code and policy definitions in this repository:
- are **not production-grade**
- have **not been security-hardened**
- do **not include full error handling, retry logic, or scale safeguards**
- may require adaptation for large or complex environments

**Do not deploy this directly to production** without:
- thorough review,
- testing in a non-production environment,
- and validation against your organization’s security, governance, and licensing requirements.

The authors assume **no responsibility** for unintended changes, licensing implications, or operational impact resulting from use of this code.

---

## Intended audience

This repository is intended for:
- Cloud / Solution Architects
- Azure Governance and Policy practitioners
- Engineers learning Azure Policy `DeployIfNotExists` patterns
- Customers exploring Azure Arc SQL Server licensing automation

---
