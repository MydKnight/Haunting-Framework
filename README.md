# Haunting-Framework

Ansible-based Raspberry Pi fleet management framework for a Magic Castle interactive Halloween experience. The canonical active repo for all Pi haunt work going forward.

---

## Current Status

**Dormant** — last commit Sep 2024. Framework layer is functional: Ansible provisioning works, Node-Red is wired. No gag-level Python scripts have been ported yet. The haunt has not run on this version.

**Known gaps:**
- No hardware abstraction layer (GPIO, DMX, RFID, audio) — exists in `PiClasses` (Gen 2), needs porting to Python 3
- No gag scripts — most complete versions exist in `Inferno2.0` (Gen 3)
- No member lookup system — backend exists in `Castle-Backend` (Gen 3, Node.js/Express/MySQL)
- No telemetry/error tracking — Sentry integration existed in Gen 3
- No tests

**Revive decision:** ~Aug 2026 (seasonal — only relevant pre-Halloween)

---

## What It Does

This framework manages a fleet of Raspberry Pis that drive interactive gags for a Halloween event at the Magic Castle. Pis control physical hardware (DMX lighting rigs, RFID readers, GPIO relays, audio) and coordinate with each other to trigger multi-step experiences when a guest interacts with a prop.

The framework handles:
- **Fleet management** — provisioning, SSH deployment, remote management of all Pis
- **Event choreography** — Node-Red flows that sequence hardware triggers in time
- **Gag scripts** — per-gag Python scripts that read sensors and drive outputs
- **Member system** (Gen 3 capability) — RFID-triggered member lookup, personalized responses
- **Telemetry** (Gen 3 capability) — remote error tracking via Sentry

---

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Fleet management | Ansible + Docker | Replaced Balena (see below) |
| Event choreography | Node-Red | Visual flow editor, wired in Gen 4 |
| Gag scripts | Python 3.9 | Pi-side logic |
| Pi provisioning | Ansible playbooks | SSH-based, inventory in `ansible/inventory/hosts` |
| Container runtime | Docker | Ansible runs inside a container |
| Error tracking | Sentry SDK | Gen 3 capability — not yet in Gen 4 |
| Backend API | Node.js / Express / MySQL | Gen 3 capability — lives in archived `Castle-Backend` |

### A note on Balena

Generations 2 and 3 used **Balena** (formerly resin.io) for fleet management. Balena provided an excellent dashboard for remote shell access, remote shutdown/restart, and OTA code pushes via `Dockerfile.template`. It has since transitioned to a paid service that is outside the budget for a private project. **Balena should not be assumed going forward.** Ansible replaces it in Gen 4.

---

## Generational History

This repo is Gen 4. Three prior generations exist across archived repos — their capabilities are documented below so nothing is lost.

### Gen 1 — 2015 (Halloween2015, Christmas-2015, NYE2015)

Flat Python 2 scripts, one file per gag. No framework, no fleet management, manual deployment.

**Capabilities:**
- RFID triggering via USB HID (keyboard emulation, `raw_input` loop)
- DMX lighting control via USB-RS485 serial adapter
- GPIO relay control (solenoids, props)
- Audio playback via `mpg321`
- Per-event iterations: Halloween, Christmas, NYE — each in its own repo

**Gaps vs. later gens:** No reusable library, no fleet management, no telemetry, no coordination between Pis, no member system.

---

### Gen 2 — 2018 (PiClasses)

Introduced a shared Python 2 class library. Still Balena for fleet management.

**Capabilities (via reusable classes):**
- `BaseScript.py` — base class for all gag scripts
- `GPIOLib.py` — GPIO abstraction (relays, inputs)
- `DmxPy.py` — DMX lighting control (USB-RS485)
- `Movies.py` / `InfoBeamer.py` — video looping via info-beamer-pi (UDP control on `localhost:4444`)
- `WriteLogToDB.py` — telemetry pipeline: writes gag events to a database
- Balena fleet management (OTA push via `Dockerfile.template`)

**Gaps vs. later gens:** Python 2, no UART RFID, no inter-Pi UDP messaging, no member system, no TTS.

---

### Gen 3 — 2021 (Inferno2.0 + Castle-Backend)

Most feature-complete generation. Two repos working in tandem: Pi-side Python (`Inferno2.0`) and cloud backend (`Castle-Backend`).

**Pi-side capabilities (Inferno2.0):**
- RFID reading via hardware UART serial (more reliable than USB HID)
- Member lookup — RFID badge → REST API call → member name/data
- Text-to-speech via `pyTTS` / `espeak` — personalized audio responses
- UDP broadcast for coordinated multi-Pi gag sequencing
- BCD GPIO output (binary-coded decimal hardware addressing)
- Threaded architecture (RFID reader on background thread, main loop non-blocking)
- Sentry SDK for remote error tracking and crash reporting
- Balena fleet management

**Backend capabilities (Castle-Backend):**
- Node.js / Express REST API
- `GET /members/:badge_id` — RFID badge lookup → returns member record
- `POST /activation` — logs gag activation events
- MySQL database
- Deployed to AWS Elastic Beanstalk
- Sentry integration

**Gaps vs. Gen 4:** Balena dependency (paid), no Ansible/Docker self-hosted management, no Node-Red choreography layer.

---

### Gen 4 — 2024 (Haunting-Framework — this repo)

**Capabilities:**
- Ansible provisioning of Pi fleet (SSH-based, inventory-driven)
- Ansible runs in Docker container — no host-side Ansible install needed
- Node-Red wired for event choreography
- Python 3.9 target
- Self-hosted — no paid services required

**Not yet implemented (see roadmap below):**
- Hardware abstraction layer (GPIO, DMX, RFID, audio)
- Gag scripts
- Member system
- Telemetry

---

## Capability Roadmap

Organized by layer. Each layer depends on the one below it. Goal state for a fully operational haunt:

| Layer | Capability | Status | Source to port from |
|---|---|---|---|
| 0 — Fleet | Ansible provisioning + SSH management | ✓ Done | — |
| 0 — Fleet | Node-Red choreography | ✓ Wired | — |
| 1 — Hardware | GPIO abstraction (relays, inputs) | ✗ Not started | `PiClasses/GPIOLib.py` |
| 1 — Hardware | DMX lighting (USB-RS485) | ✗ Not started | `PiClasses/DmxPy.py` |
| 1 — Hardware | RFID reading (hardware UART preferred) | ✗ Not started | `Inferno2.0/IC-Columns/IC-Columns.py` |
| 1 — Hardware | Audio playback | ✗ Not started | Gen 1 `mpg321` or update approach |
| 1 — Hardware | Video looping (info-beamer-pi, UDP port 4444) | ✗ Not started | `PiClasses/InfoBeamer.py` |
| 2 — Telemetry | Sentry error tracking | ✗ Not started | `Inferno2.0` Sentry integration |
| 2 — Telemetry | Local event logging | ✗ Not started | `PiClasses/WriteLogToDB.py` (adapt) |
| 3 — Member system | REST backend (Node.js/Express/MySQL) | ✗ Not started | `Castle-Backend` (archived) |
| 3 — Member system | Member lookup from RFID | ✗ Not started | `Inferno2.0/IC-Columns/IC-Columns.py` |
| 4 — Gags | Per-gag Python scripts using layers 0-3 | ✗ Not started | `Inferno2.0` as reference |
| 4 — Gags | UDP inter-Pi coordination | ✗ Not started | `Inferno2.0` UDP broadcast |
| 4 — Gags | Text-to-speech (pyTTS/espeak) | ✗ Not started | `Inferno2.0` TTS implementation |
| 5 — Choreography | Node-Red flows for gag sequencing | ✗ Not started | Design from scratch |
| 6 — Receipt | Receipt printer integration | ✗ Aspirational | No prior implementation |

---

## Archived Repos

The following repos represent prior generations of this work. All have been archived. The code is preserved in GitHub if specific implementations need to be referenced during a revival.

| Repo | Generation | Key capability to reference |
|---|---|---|
| Halloween2015 | Gen 1 | Original flat gag scripts (DMX, RFID, GPIO, audio) |
| Christmas-2015 | Gen 1 | Christmas event variant |
| NYE2015 | Gen 1 | NYE event variant |
| GeneralUse | Gen 1 | Shared utility scripts |
| PiClasses | Gen 2 | Python class library (GPIOLib, DmxPy, InfoBeamer, WriteLogToDB) |
| InteractiveGagFramework | Gen 2 | Vision/design document — never built |
| Inferno2.0 | Gen 3 | Most sophisticated gag scripts (RFID, TTS, UDP, Sentry, member lookup) |
| Castle-Backend | Gen 3 | Node.js/Express/MySQL member backend (AWS EB) |

---

## Setup

### Prerequisites
- Docker installed on your management machine
- SSH access to all Pis (keys configured)
- Pis listed in `ansible/inventory/hosts`

### Run Ansible commands

```bash
# Ping all hosts
docker run -it --rm -v "$(pwd)/ansible:/ansible" ansible-container ansible all -m ping -i /ansible/inventory/hosts

# Provision a Pi
docker run -it --rm -v "$(pwd)/ansible:/ansible" ansible-container ansible-playbook /ansible/playbooks/provision_generic_pi.yml -i /ansible/inventory/hosts
```

### Node-Red
Node-Red is configured to start via Ansible provisioning. Access the flow editor at `http://<pi-ip>:1880` after provisioning.
