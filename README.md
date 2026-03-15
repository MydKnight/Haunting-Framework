# Haunting-Framework

Raspberry Pi haunt framework — the canonical reference for 6 years of interactive event builds (2015–2021) at the Magic Castle. Gens 1–3 delivered working gags via Python + Balena. Gen 4 (this repo) pivots to Ansible + Docker + Node-Red as the successor framework — scaffolded but not yet brought to delivery.

---

## How to Use This Document

If you're picking this project up again, **start here before writing any code.** This README is the accumulated memory of 6 years of building interactive gags. It documents every capability ever built, what worked, what didn't, what was never finished, and the architecture lessons learned the hard way. The goal for any future revival is to build the framework layers first so that individual gags become easy to assemble — not to dive straight into a specific gag and reinvent the wheel again.

---

## Current Status

**Dormant** — last commit Sep 2024. The prior history (Gens 1–3, 2015–2021) is the delivered work — fully archived. Gen 4 (this repo) is the successor framework: Ansible provisioning scaffolded, Node-Red wired up, but **no gag scripts ported, no hardware abstraction layer, haunt has never run on this version.**

**Known gaps:**
- No hardware abstraction layer (GPIO, DMX, RFID, audio) — prior implementations exist in archived repos, need porting to Python 3
- No gag scripts
- No inter-Pi messaging abstraction
- No member lookup system
- No telemetry/error tracking
- No process watchdog
- No tests
- No CLAUDE.md — write this before starting any revival work

**Revive decision:** ~Aug 2026 (seasonal — only relevant pre-Halloween)

---

## What It Does

A fleet of Raspberry Pis drives interactive prop gags for a Halloween event at the Magic Castle. Each Pi controls physical hardware (DMX lighting rigs, RFID readers, GPIO relays, audio) and coordinates with other Pis to trigger multi-step experiences when a guest interacts with a prop.

This repo manages:
- **Fleet management** — provisioning, SSH deployment, remote management of all Pis
- **Event choreography** — Node-Red flows that sequence hardware triggers in time
- **Gag scripts** — per-gag Python scripts that read sensors and drive outputs
- **Member system** (Gen 3 capability, not yet ported) — RFID badge → member name lookup → personalized responses
- **Telemetry** (Gen 3 capability, not yet ported) — remote crash tracking via Sentry

---

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Fleet management | Ansible + Docker | Replaced Balena — see note below |
| Event choreography | Node-Red | Visual flow editor, wired in Gen 4 |
| Gag scripts | Python 3.9 | Pi-side logic |
| Pi provisioning | Ansible playbooks | SSH-based, inventory in `ansible/inventory/hosts` |
| Container runtime | Docker | Ansible runs inside a container — no host-side install needed |
| Video looping | info-beamer-pi | UDP control on `localhost:4444` |
| Error tracking | Sentry SDK | Gen 3 capability — not yet in Gen 4 |
| Backend API | Node.js / Express / MySQL | Gen 3 capability — lives in archived `Castle-Backend` |

### Fleet Management: Why Ansible Replaced Balena

Prior generations (2018, 2021) used **Balena** (formerly resin.io) for fleet management. Balena was excellent — dashboard for remote shell access, OTA code pushes via `Dockerfile.template`, remote shutdown/restart. However, Balena has since moved to a paid service model that's out of budget for a personal project.

**Ansible + Docker replaces everything Balena provided:**
- OTA deploys → `ansible-playbook` push
- Remote shell → `ansible` ad-hoc commands or direct SSH
- Pi provisioning → Ansible playbooks
- All self-hosted, no ongoing cost

Do not reintroduce Balena. The `Dockerfile.template` files visible in archived repos are Balena artifacts — they are not standard Docker files.

---

## The Framework-First Principle

Every prior year, gags were built as standalone scripts that reimplemented the same plumbing from scratch: RFID reading, DMX control, GPIO handling, inter-Pi messaging. The result was working gags but no reusable foundation. Each year started from near-zero.

**The right approach for any future revival:**

1. Build the hardware abstraction layer (GPIO, DMX, RFID, audio) as importable Python 3 modules — test them on the bench before touching a gag
2. Build the inter-Pi messaging abstraction — a clean send/receive pattern usable by any gag
3. Build the process watchdog — gags need to auto-restart without intervention
4. Wire Node-Red for choreography
5. *Then* write gag scripts that import from the above

A gag script built on a solid framework should be ~50-100 lines. A gag script that contains its own RFID reader, DMX driver, and UDP socket from scratch will be 400+ lines and impossible to maintain.

---

## Complete Event History

Six events were built across 9 years. Each year's code lives in the archived repos listed at the bottom of this document. **The 2019 code is missing from version control** — see note under that year.

---

### 2015 — Sleepy Hollow (`Halloween2015`, master branch)

Flat Python 2 scripts, one per gag. No shared library, no fleet management, manual deploy. The first year everything worked end to end.

**Gags:**
| Gag | Trigger | Hardware | Notes |
|---|---|---|---|
| BrawlFight | RFID | info-beamer video | Plays fight scene clip |
| Bridge | Timed (60s loop) | Audio only | Ambient horse sounds, no trigger |
| DinRmClouds | RFID | DMX + audio | Dining room atmosphere |
| Fireflies | RFID | GPIO relay × 3 | mod3 routing — each RFID deterministically routes to one of 3 firefly zones |
| Furnace | RFID | DMX + info-beamer video | DMX gold→red color shift + furnace video |
| LarasCandle | RFID | GPIO relay (inverted) | Candle prop — relay is active-low |
| LivingLogo | Ambient | info-beamer video | Logo animation loop, no trigger |
| Mill | Ambient | info-beamer video | Mill video loop, no trigger |
| Pumpkins | RFID or SIGALRM (5 min) | 62-ch DMX + audio | Most complex Gen 1 gag: random choice between 62-channel DMX lightshow (pumpkin tree) or sequential narrated audio with DMX fade (pumpkin talk). Audio duration tracked via `mutagen`. |
| Stables | RFID | GPIO relay × 3 + audio | Choreographed sequence: stop barn ambient → horse audio → relay sequence for nose/eyes/barn door flapping → restart ambient |
| Trixie | RFID | GPIO + audio | Simple: GPIO on → laugh audio → GPIO off |

**Shared utilities introduced:**
- `AudioRandomizer.py` — random audio from folder with no-repeat tracking
- `DmxPy.py` — DMX USB-RS485 driver (inline, later became a class)
- `Lights.py` — GPIO relay abstraction (on/off, activatePins, showColor)
- `Logging.py` — MySQL telemetry. **Note: credentials hardcoded directly in source — this is an anti-pattern. Never repeat this. Use `.env` + `.env.example`.**
- `Movies.py` — info-beamer UDP wrapper (`localhost:4444`, `looper/set:intermission` / `looper/set:loop`)
- `Scripts/disableRFID.sh` + `enableRFID.sh` — OS-level RFID enable/disable for debounce

---

### 2015 — Christmas + NYE (`Christmas-2015`, `NYE2015`, master branches)

Same framework as Sleepy Hollow. New event-specific gags, plus early experiments with display output.

**Christmas gags:**
| Gag | Notes |
|---|---|
| DiningRoom | RFID → 4-channel DMX burst + audio |
| Furnace | RFID + DMX variant |
| NaughtyNice | RFID → pygame display (parchment background, text fade-in, odd/even routing for naughty/nice GPIO). **Partially built, never delivered** — rendering arbitrary text to the display exceeded 2015 skill level. The concept is solid and worth revisiting. |
| SantasWindow | **Time-of-day content switching** — 6am–12pm plays DayLoop video, otherwise NightLoop + RFID triggers intermission |
| Snowfall | Video loop + RFID triggers intermission |

**New capabilities introduced:**
- Time-of-day logic (`datetime`) — ambient content changes based on time of day
- `pygame` display output on connected monitor (partial — text rendering worked but full gag was not delivered)
- info-beamer Lua scripting confirmed (`NaughtyNice/node.lua`)

---

### 2016 — Dia De Los Muertos (`PiClasses`, `Halloween2016` branch)

First year with a shared class library. Gags import from PiClasses rather than carrying inline copies.

**Gags:** AltarCandles, DaiVernon, ElfWindow, Furnace, Gumballs, HallOfFame, Heartbeat, Henning, Houdini, InfoAltar, OwlHat, Skelley-Eyes, Skulls, Spider, Trixie, SantasWindow

**New class library (PiClasses root):**
- `GPIOLib.py` — GPIO abstraction class
- `DmxPy.py` — DMX class
- `InfoBeamer.py` — info-beamer UDP wrapper
- `Logging.py` — expanded MySQL logging class
- `Timer.py` — reusable timer

**New capabilities introduced:**
- Reusable class library — gags are now short import-and-use scripts
- Heartbeat relay effect (timed pulsing pattern)
- Balena fleet management (OTA push, remote dashboard) — first appearance

---

### 2017 — Invasion (`PiClasses`, `Halloween2017` branch)

The most architecturally ambitious year. Introduced inter-Pi communication as a class, stepper motors, process watchdog, and a formal gag template.

**Gags:** AlienJars, AntHead, Button, Detector, ETComm, GeigerCounter, HallCore, LauraRadio, PalaceBar, Radio, RobotVoice, Stanchions, Trixie (+ carried over from 2016)

**Most important new additions:**
| File | What it does |
|---|---|
| `Communicator.py` + `CommunicatorClient.py` | **First formalized UDP inter-Pi communication class.** Server and client abstractions — any gag can now send/receive Pi-to-Pi messages without writing raw sockets. This is the pattern that should be built properly in the framework. |
| `Button.py` | Button input abstraction with debounce (4KB — substantial) |
| `StepperController.py` | **Stepper motor control** — new hardware type |
| `GeigerCounter.py` | Geiger counter prop (GPIO-based, alien/radiation theme) |
| `RobotVoice.py` | Robot voice synthesis |
| `Template.py` | **First formal gag template** — the intended starting point for any new gag |
| `monitor_process.py` + `monitor_reboot.py` | **Process watchdog** — watches the gag process, reboots Pi if it crashes |
| `service.sh` + `launch_process.sh` | Service wrapper to launch gag + watchdog together |
| `HallCore.py` | Central hall controller (8.6KB — most complex script of this generation) |
| `PalaceBar.py` | Palace Bar gag (6.3KB) |
| `Radio.py` / `LauraRadio.py` | Scripted radio/audio playback gags |

**New capabilities introduced:**
- Formalized inter-Pi UDP messaging class
- Stepper motor hardware
- Button input abstraction with debounce
- **Process watchdog / auto-restart** — critical for unattended operation
- Formal gag template
- Robot voice synthesis

---

### 2018 — Murder Mansion (`PiClasses`, `Halloween2018` branch, gags in `2018/` subdirectory)

Consolidated the class library further. Introduced `BaseScript.py` as the formal parent class for all gags, and a proper database abstraction so credentials are no longer in gag scripts.

**Gags:** BlacklightPortraits, BloodyMace, BodyOutline, Conversation, FlowerWind, HughWelcome, IntroVideo, Invitation, KillerReveal, KnifeCircle, OuijaBase + OuijaRemote, RubyPortrait, Speakeasy + SpeakeasyWindow, Trixie, UrbanSlums, WhisperingWall, WineGlass

**Key gags:**
| Gag | Notes |
|---|---|
| OuijaBase + OuijaRemote | Two-Pi Ouija board gag. Master Pi runs the board logic, slave Pi controls the planchette movement via UDP. Another instance of the multi-Pi pattern. |
| Speakeasy + SpeakeasyWindow | Prohibition speakeasy — RFID trigger + video window (3.5KB + 1.4KB) |
| KillerReveal | Murder mystery reveal mechanic |
| FlowerWind | Fan + flower prop combo (GPIO fan + relay) |
| WhisperingWall | Audio-only atmospheric gag |

**Class library evolution:**
- `BaseScript.py` — formal base class for all gags (first at root level)
- `WriteLogToDB.py` — database telemetry (fully abstracted)
- `databaseLib.py` — database connection abstraction (credentials no longer in gag code)
- `Logger.py` — standalone logging class

---

### 2019 — Cursed Temple (**CODE NOT IN VERSION CONTROL**)

This year happened but the code was never committed to GitHub. No branch, no repo, no files found via code search. Gags known to have been built: Shrunken Heads, Boulder Fall, Idol Swap, Treasure Map (and possibly others).

If the code still exists it would be on a Pi SD card or a local machine from that era. For practical purposes, treat the 2019 implementation as lost. Any future Cursed Temple revival starts from the framework, not recovered code.

---

### 2021 — Dante's Inferno (`Inferno2.0` + `Castle-Backend`, master branches)

Most feature-complete year. Two repos: Pi-side Python (`Inferno2.0`) and a cloud REST backend (`Castle-Backend`). First year with personalized member experiences, Sentry crash reporting, Pi Camera, Twitter integration, and a fully delivered receipt printer.

**Gags:**
| Gag | Notes |
|---|---|
| IC-Columns | RFID → member lookup → TTS personalized announcement → BCD GPIO output → UDP to IC-Column-Remote slave Pi |
| IC-Column-Remote | UDP slave: receives column commands → drives 3 GPIO LEDs (R/G/B) |
| Inferno-Sorter | RFID → member lookup → hell level determination → TTS → UDP to PrinterTester → thermal receipt print |
| PrinterTester | UDP receiver → CUPS thermal printer (ZJ-58 / ZJ-80). **Fully delivered**, not aspirational. Docker-managed CUPS container. |
| InfernoEscape | Button press → RFID identity check → random escape/damnation outcome → DMX lighting → Pi Camera photo → audio from outcome pool (SalvationAudio / DamnationAudio) → TTS personalized message → **Twitter post with photo** + FTP upload to personal site |

**New capabilities introduced:**
- RFID via hardware UART serial (more reliable than USB HID)
- Member system: RFID → REST API → member name + HellLevel (1–9, Dante's circles). Fallback: derive level from RFID first hex character.
- Threaded RFID reader (background thread, non-blocking main loop)
- Sentry SDK — remote crash reporting on every Pi
- **Thermal receipt printer** — CUPS + ZJ-58/ZJ-80, UDP-triggered from another Pi. Docker container for CUPS.
- **Pi Camera** — `picamera`, 1024×768, timestamped JPG capture
- **Social/photo sharing** — Twitter post (`twython`) with captured photo + personalized message. **Lesson learned: Twitter API was fragile and dependency-heavy. Future implementations should not be Twitter-dependent — consider a local web gallery or a more stable API.**
- FTP upload to personal website (`ftplib`)

**Backend (`Castle-Backend`):**
- Node.js / Express REST API
- `GET /members/:badge_id` — RFID lookup → member record
- `POST /activation` — logs gag activations
- MySQL, deployed on AWS Elastic Beanstalk, Sentry integrated

---

## Architecture Lessons Learned

These are the hard-won patterns from 6 years. Build to these, don't rediscover them.

### Multi-Pi Communication
The pattern of one Pi sending UDP commands to another was implemented at least 4 times across the years (IC-Columns→Remote, Sorter→Printer, Ouija master→remote, 2017 Communicator class). Each time it was partially abstracted or reinvented. **Build a proper inter-Pi messaging module first** — a clean `send(target_ip, message)` / `listen(port, callback)` abstraction — and all gags that need multi-Pi coordination can use it without writing sockets.

### Process Watchdog
Gags running unattended for 4+ hours will crash. The 2017 `monitor_process.py` + `monitor_reboot.py` system auto-restarts crashed scripts. **This is not optional infrastructure.** Build it into the framework from the start.

### Credentials
Gen 1 hardcoded MySQL credentials directly in `Logging.py`. Don't do this. All secrets go in `.env` files (gitignored), documented in `.env.example`. This applies to database connections, API keys, Sentry DSNs, and anything similar.

### Photo Booth Pattern
The InfernoEscape gag is a fully-featured photo booth: trigger → photo → outcome determination → audio → display/post result. This is a reusable pattern that could underpin multiple gags across different themes. **The Twitter dependency made it fragile** — API changes broke it mid-event. Future photo booth implementations should target something self-hosted (local web gallery, NAS upload) rather than a third-party social API.

### RFID Reading
USB HID (keyboard emulation) is simpler to set up but has edge cases around focus and device state. Hardware UART serial (Gen 3 approach) is more reliable for production. Use UART.

### Gag Template
`PiClasses/Halloween2017/Template.py` was the first attempt at a formal gag template. When building new gags, start from a template that imports the framework modules — don't start from scratch.

### Balena → Ansible
The fleet management capability Balena provided (OTA push, remote shell, Pi health dashboard) is fully replaced by Ansible. The tradeoff is that Ansible requires more explicit scripting vs. Balena's dashboard UI, but it's free, self-hosted, and not subject to pricing changes. The `Dockerfile.template` files in archived repos are Balena artifacts — they are not standard Dockerfiles.

---

## Build Order for Next Revival

When the time comes to revive this, work in this order. Do not jump to gag scripts until the layers below them exist.

| Step | What to build | Why first |
|---|---|---|
| 1 | Write CLAUDE.md for this repo | Captures architecture decisions before writing any code |
| 2 | Verify Ansible fleet still works — reprovision a Pi | Everything else runs on the fleet |
| 3 | Python 3 hardware modules: GPIO, DMX, RFID (UART), audio | Every gag needs these — port from archived repos |
| 4 | Inter-Pi messaging module (UDP send/receive) | Multi-Pi gags need this; build once |
| 5 | Process watchdog | Gags will crash; need auto-restart before going to event |
| 6 | Sentry integration | Remote crash visibility |
| 7 | Gag template | Starting point for each new gag |
| 8 | Node-Red flows | Choreography layer wired to gag triggers |
| 9 | First gag end-to-end | Validate the stack works before building more |
| 10 | Member system (optional) | Only if personalized experiences are wanted |
| 11 | Photo booth module (optional) | Only if camera gag is planned — use self-hosted output, not Twitter |
| 12 | Thermal printer (optional) | Reference `Inferno2.0/PrinterTester` — CUPS + ZJ-58/ZJ-80 + Docker |

---

## Capability Reference

Everything that has been built across all generations. Check here before assuming something needs to be built from scratch.

### Hardware outputs
| Capability | Status in Gen 4 | Reference |
|---|---|---|
| GPIO relay (on/off, inverted-logic) | ✗ Not ported | `PiClasses/GPIOLib.py`, `Halloween2015/Lights.py` |
| DMX lighting (USB-RS485, up to 62+ channels) | ✗ Not ported | `PiClasses/DmxPy.py` |
| Audio — mpg321 (blocking + background) | ✗ Not ported | All Gen 1+ gags |
| Audio — random selection, no-repeat | ✗ Not ported | `Halloween2015/AudioRandomizer.py` |
| Audio — sequential with duration tracking | ✗ Not ported | `Halloween2015/Pumpkins.py` (mutagen) |
| Audio — outcome pools (e.g. salvation/damnation) | ✗ Not ported | `Inferno2.0/InfernoEscape` |
| Video — info-beamer loop/intermission via UDP | ✗ Not ported | `PiClasses/InfoBeamer.py` |
| TTS — espeak/pyTTS | ✗ Not ported | `Inferno2.0/InfernoEscape/TextToSpeech.py` |
| Thermal printer — CUPS + ZJ-58/ZJ-80, UDP trigger | ✗ Not ported | `Inferno2.0/PrinterTester` |
| Stepper motor | ✗ Not ported | `PiClasses/Halloween2017/StepperController.py` |
| Pi Camera (photo capture) | ✗ Not ported | `Inferno2.0/InfernoEscape/InfernoEscape.py` |
| pygame display output | ✗ Not ported | `Christmas-2015/NaughtyNice.py` (partial) |

### Triggers
| Capability | Status in Gen 4 | Reference |
|---|---|---|
| RFID — hardware UART serial (preferred) | ✗ Not ported | `Inferno2.0/IC-Columns/IC-Columns.py` |
| RFID — USB HID / raw_input (legacy) | ✗ Not ported | All Gen 1–2 gags |
| Physical button (GPIO input with debounce) | ✗ Not ported | `PiClasses/Halloween2017/Button.py` |
| SIGALRM timed trigger (ambient shows) | ✗ Not ported | `Halloween2015/Pumpkins.py` |
| Time-of-day content switching | ✗ Not ported | `Christmas-2015/SantasWindow.py` |
| UDP command from another Pi | ✗ Not ported | `Inferno2.0/IC-Column-Remote/IC-Column-Remote.py` |

### Framework / infrastructure
| Capability | Status in Gen 4 | Reference |
|---|---|---|
| Inter-Pi UDP messaging | ✗ Not ported | `PiClasses/Halloween2017/Communicator.py` |
| Process watchdog / auto-restart | ✗ Not ported | `PiClasses/Halloween2017/monitor_process.py` |
| Sentry crash reporting | ✗ Not ported | `Inferno2.0` Sentry integration |
| Member lookup (RFID → REST API → member data) | ✗ Not ported | `Castle-Backend`, `Inferno2.0/IC-Columns` |
| Database telemetry | ✗ Not ported | `PiClasses/WriteLogToDB.py`, `databaseLib.py` |
| Gag template | ✗ Not ported | `PiClasses/Halloween2017/Template.py` |

---

## Archived Repos Reference

The following repos are archived on GitHub. Code is preserved and readable.

| Repo | Branch | Year | Theme | What to look for |
|---|---|---|---|---|
| Halloween2015 | master | 2015 | Sleepy Hollow | Flat gag scripts, DMX, GPIO relay patterns, info-beamer, SIGALRM timer, 62-ch DMX (Pumpkins) |
| Christmas-2015 | master | 2015 | Christmas | Time-of-day switching (SantasWindow), pygame display (NaughtyNice — partial) |
| NYE2015 | master | 2015–16 | NYE | NYE variants of base gags |
| GeneralUse | master | 2016 | Transitional | Early 2016 scripts before PiClasses was established |
| PiClasses | Halloween2016 | 2016 | Dia De Los Muertos | First class library: GPIOLib, DmxPy, InfoBeamer, Timer |
| PiClasses | Halloween2017 | 2017 | Invasion | Communicator UDP class, StepperController, Button, process watchdog, Template, GeigerCounter |
| PiClasses | Halloween2018 | 2018 | Murder Mansion | OuijaBase/Remote two-Pi gag, BaseScript.py, databaseLib, WriteLogToDB |
| InteractiveGagFramework | master | ~2016 | Vision doc | Architecture vision document — never built, but still useful framing |
| Inferno2.0 | master | 2021 | Dante's Inferno | RFID UART, member system, TTS, Sentry, Pi Camera, photo booth, thermal printer, multi-Pi |
| Castle-Backend | master | 2021 | Backend | Node.js/Express/MySQL member API — `/members/:badge_id`, `/activation` |

---

## Setup

### Prerequisites
- Docker installed on your management machine
- SSH access to all Pis (keys configured in `~/.ssh/`)
- Pi IPs listed in `ansible/inventory/hosts`

### Run Ansible commands

```bash
# Ping all hosts
docker run -it --rm -v "$(pwd)/ansible:/ansible" ansible-container ansible all -m ping -i /ansible/inventory/hosts

# Provision a Pi
docker run -it --rm -v "$(pwd)/ansible:/ansible" ansible-container ansible-playbook /ansible/playbooks/provision_generic_pi.yml -i /ansible/inventory/hosts
```

### Node-Red
Node-Red starts via Ansible provisioning. Access the flow editor at `http://<pi-ip>:1880`.

### Secrets
All secrets (database credentials, API keys, Sentry DSNs) go in `.env` files. Never commit credentials to source control — this was done in Gen 1 and is an anti-pattern to avoid.
