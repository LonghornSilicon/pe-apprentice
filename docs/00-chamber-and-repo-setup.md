# Chamber and Repo Setup

*Setup. Do this once, before week 2. Not optional.*

Everything in this program runs on the Longhorn Silicon Cadence chamber. This
document gets you from "I have an account" to "the tools run and I can submit
work." Nothing in weeks 2 through 11 works until it is done.

Budget an hour. If you hit something this document does not cover, stop and get
a lead — do not improvise around it. A chamber is a shared multi-tenant machine
and improvising on it affects other people.

---

## 0. What you need first

| Thing | Where it comes from |
|---|---|
| A Cadence chamber account | Provisioned by Cadence, requested by a lead. **This is not your UT EID** — it is a separate username and password issued to you. |
| UT Austin VPN, connected | The chamber is on a private network. Nothing below works off-VPN. |
| Your account cleared for tool licenses | A lead has to request this. See §1. Do not skip reading it. |

### The one thing that will bite you if nobody warns you

New chamber accounts are provisioned as *courseware* accounts, and courseware
accounts sit on a license-server exclude list for some tools — notably Genus
synthesis. The licenses are free and available; the exclusion is administrative.
Nothing tells you this until a tool refuses to start in week 7.

**A lead must email the CAD admin to have every apprentice account added before
week 1.** If you are a lead reading this: do it now, it has lead time. If you
are an apprentice and §4's smoke test fails on a license error, this is why —
report it, do not try to work around it.

---

## 1. Getting in

You reach the chamber through **ETX**, a browser-based remote desktop. Plain
`ssh` will not work: the chamber blocks SSH command execution.

1. Connect to the UT Austin VPN.
2. Open the ETX portal (a lead will give you the URL) and log in with your
   Cadence chamber username and password.
3. You land on the **login node**, `ae03ut01`, in a `csh` shell.

### Immediately get off the login node

The login node is shared by everyone and is sized for light interactive work.
Real tool runs belong on a compute node, which is scheduled — your job gets
guaranteed CPU and memory, and you are not degrading everyone else's session.

```
% bash                              # the launchers are bash; csh is the login default
% qsh -q normal.q -now n -V         # request an interactive compute shell with X11
% bash                              # qsh drops you back into csh, so do it again
```

You should now see a hostname like `ip-10-2-6-219` rather than `ae03ut01`. That
is how you know you are on compute. **Do this every session.** Every command in
every handout assumes you are on a compute node.

### Why `which genus` prints nothing, and why that is fine

`/apps/<TOOL>` on this chamber is an **autofs** mount: the software is not
visible until something touches the path. So this is expected and is *not* a
sign anything is broken:

```
% which genus
%                                   # nothing. correct.
% module load genus/211/21.18.000
% which genus
/apps/GENUS211/21.18.000/tools/bin/genus
```

Load first, then check. A bare `ls /apps` before loading always under-reports.
This is the single most common false alarm on this chamber.

---

## 2. Get the repo onto the chamber

The chamber cannot reach GitHub, so the repo travels as a **git bundle** — a
single file holding the full history, which you can clone from exactly like a
real remote.

On a machine that has GitHub access:

```
% git clone git@github.com:LonghornSilicon/pe-apprentice.git
% cd pe-apprentice
% git bundle create pe-apprentice.bundle --all
```

Transfer `pe-apprentice.bundle` to the chamber (ETX has a file-transfer panel;
a lead will show you). Then, on the chamber:

```
% mkdir -p ~/longhorn-apprentice
% cd ~/longhorn-apprentice
% git clone ~/pe-apprentice.bundle pe-apprentice
% cd pe-apprentice
% git checkout -b <your-chamber-username>
```

You now have a real git repo with real history. It just has no live remote —
§5 covers how work gets back out.

When a lead ships an update later in the semester, it arrives as a smaller
bundle:

```
% git fetch ~/update-weekN.bundle main:update-weekN
% git merge update-weekN
```

---

## 3. Install the tooling

```
% bash ~/longhorn-apprentice/pe-apprentice/tools/install.sh
```

This symlinks the helper scripts into `~/bin/`, creates your run area at
`~/work/pe/`, and runs `chamber-diagnose`. It is idempotent — re-run it any time.

### Where things live, and why it matters

| | Path | Written by | Survives? |
|---|---|---|---|
| Source | `~/longhorn-apprentice/pe-apprentice` | you | it is git; treat it as the truth |
| Runs | `~/work/pe` | tools | not in git, never cleaned by git |
| Scratch | `/tmp/$USER-pe` | tools, as fallback | wiped on reboot |

Tool output goes **outside** the repo on purpose. A `git checkout` can never
destroy a run, and a run can never dirty your `git status`. Do not fight this by
running tools from inside the repo.

### Disk is tight — this is a real constraint, not boilerplate

Home directories are **20 GB**, on NFS, and that is the only persistent
writable space you have. An Innovus place-and-route run directory is easily
1–3 GB. Four or five runs will fill your account, and a full home fails in
confusing ways rather than with a clean "disk full."

Check yours before week 8, and check it again during weeks 9 and 10:

```
% df -h ~
```

Each step directory keeps every run so you can compare a broken run against the
last good one, which is genuinely useful and also the thing that fills your
disk. Delete old run directories you have finished with:

```
% ls -lt ~/work/pe/05-innovus-pnr/          # oldest at the bottom
% rm -rf ~/work/pe/05-innovus-pnr/20260901-141233
```

---

## 4. Sanity check — this must pass before week 2

Two checks. Do not skip the second one: it is the only thing that proves the
license problem in §0 has actually been cleared for your account, and finding
that out now instead of in week 7 is the entire reason this section exists.

### 4a. Environment

```
% chamber-diagnose
```

Every line should read `[OK]`. If anything reads `[FAIL]`, the output tells you
what to do about it. The two common ones are `$DISPLAY` unset (fix it at the
ETX/X11 layer) and a tool not resolving (get a fresh compute shell with
`qsh -q normal.q -now n -V` — the compute farm is not uniform and a different
node will usually have it).

### 4b. Simulator

```
% cd ~/longhorn-apprentice/pe-apprentice
% ./01-xcelium-rtlsim/run
```

This compiles the provided smoke testbench against the empty `rtl/pe.sv` stub.
**It is supposed to FAIL its checks** — you have not written the PE yet. What
matters is that Xcelium starts, compiles, runs, and prints a result. If you see
the test report at all, your simulator works.

### 4c. Synthesis — the license check

```
% ./03-genus-synth/run
```

Genus will synthesize the stub. As with 4b, the result does not matter; the
tool starting does. If it dies with a **license** error, stop and report it to a
lead with the exact message — that is §0, and it needs an admin to fix, not you.

If all three of these behave, you are set up. Go to week 1.

---

## 5. Submitting work

Written deliverables (the photo/scan PDFs from weeks 1, 2, 4, 6, and 8) and code
deliverables both leave the chamber the same way. **Confirm the current transfer
route with a lead before your first submission** — the chamber's file transfer
is restrictive and the route is the one part of this document most likely to
change.

For code and tool output, package your commits as a bundle:

```
% cd ~/longhorn-apprentice/pe-apprentice
% git add <the files that week's handout names>
% git commit -m "week N: <short description>"
% git bundle create ~/<your-username>-weekN.bundle main..<your-username>
```

Then transfer `<your-username>-weekN.bundle` off the chamber. Each week's
handout tells you exactly which files to add — nothing more. Do not commit run
output; that is what `$PE_WORK` is for.

---

## Verified chamber state

Everything below was confirmed live on compute node `ip-10-2-6-219` on
**2026-08-16**. `tools/lib/pe-env.sh` is the single place these are written
down — do not hardcode any of them anywhere else. If something here stops
matching reality, fix `pe-env.sh` and update this table in the same commit.

| | |
|---|---|
| OS / login shell | RHEL 7 (3.10.0-1160), `/bin/csh` |
| Module system | Environment Modules v3.2.6a, `/apps/modules-v3.2.6a-64bit/Modules` |
| Compute submission | `qsh -q normal.q -now n -V` |
| Home quota | 20 GB, NFS |

| Tool | Module pin | Resolves to |
|---|---|---|
| Genus (synthesis) | `genus/211/21.18.000` | `/apps/GENUS211/21.18.000/tools/bin/genus` |
| Innovus (place & route) | `innovus/211/21.18.000` | `/apps/INNOVUS211/21.18.000/bin/innovus` |
| Xcelium (simulation) | `xcelium/2403/24.03.005` | `/apps/XCELIUM2403/24.03.005/tools/bin/xrun` |
| SimVision (waveforms) | ships with Xcelium | `/apps/XCELIUM2403/24.03.005/tools/bin/simvision` |
| Verisium Debug | `verisiumdebug/2403/24.03.001` | `/apps/VDEBUG2403/24.03.001/tools/bin/verisium` |
| Pegasus (DRC/LVS) | `pegasus/232/23.24.000` | `/apps/PEGASUS232/23.24.000/bin/pegasus` |
| Tempus (signoff STA) | `ssv/251/25.12.000` | `/apps/SSV251/25.12.000/bin/tempus` |

Genus and Innovus are deliberately pinned to the **same 21.18 release family**
because they share database format within a family. The catalog default
`innovus/251` resolves to 25.14 and would force a cross-version handoff.

PDK — **GPDK045 itself is analog-only and ships no digital standard cells.** The
digital kit is `gsclib045`, a separate IP library underneath it:

```
/process/hosted/gpdk/gpdk045/ip_libraries/gsclib045/v4p4/gsclib045/
├── timing/slow_vdd1v0_basicCells.lib     setup signoff corner (0.9 V, 125 C)
├── timing/fast_vdd1v0_basicCells.lib     hold signoff corner  (1.1 V, -40 C)
├── lef/gsclib045_tech.lef                layers, vias, design rules
├── lef/gsclib045_macro.lef               cell abstracts for place and route
├── verilog/slow_vdd1v0_basicCells.v      behavioural models -> gate-level sim
├── cdl/gsclib045.cdl                     transistor netlist -> LVS
└── gds/                                  cell layout -> GDS streamout
```

Stream-out layer map: `/process/hosted/gpdk/gpdk045/oa/v6p0/soce/streamOut.map`

Physical verification rule decks ship for **Assura** and **Diva**
(`/process/hosted/gpdk/gpdk045/oa/v6p0/{assura,diva}/`). There is no Pegasus
deck for this kit, which shapes what week 10 does — see that handout.
