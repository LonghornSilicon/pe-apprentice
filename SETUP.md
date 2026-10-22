# Setup

Do this once, before week 2. It takes about an hour.

You need a working Cadence chamber account: a username and password issued to
you, which is **not** your UT EID. A lead has the list. Everything below
assumes you have yours.

If anything below does not work the way it says, stop and ask a lead. Do not
improvise. The chamber hardware is shared with other Cadence customers; only
`/projects/library` is ours.

---

## 1. Log in

Open <https://sj-echamber.cadencecloud.net> and log in with your chamber
username and password. You land in the Collaboration Hub. Open the
**KDE Desktop** room, then open a Terminal from the desktop menu.

The prompt says `sj24lo04`. That is the login node. Its shell is `csh`; you
are about to leave it, so do not customise it.

## 2. Get onto a compute node

The login node is shared. Real work goes on a compute node, and the chamber
uses **Slurm** to hand them out:

```bash
srun --pty bash
```

Your prompt changes to another `sj24loNN` and you are in `bash`. That is how
you know it worked. The node has 24 to 44 cores and 128 GB or more; one run
of anything in this program fits with room to spare.

**Do this every time you log in.** Every command in every week assumes it.

Two Slurm habits:

- `exit` when you are done. `srun --pty bash` holds a slot on the node until
  you leave it.
- `squeue -u $USER` lists what you have running. If you closed a browser tab
  with a shell still open, this is how you find it; `scancel <jobid>` ends it.

## 3. Get the repo onto the chamber

The chamber cannot reach GitHub. Nothing on it can `git clone` from the
internet. So the repo travels as a **git bundle**: one binary file containing
the entire repository and its history, which you then clone from as if it were
a normal remote.

### 3a. Make the bundle, on your laptop

```bash
cd /tmp
git clone https://github.com/LonghornSilicon/pe-apprentice.git
cd pe-apprentice
git bundle create /tmp/pe.bundle --all
ls -lh /tmp/pe.bundle
```

`--all` includes every branch and tag. The file is a few hundred KB.

### 3b. Upload it

There is no SFTP into this chamber. Files go in through the hub: the
**Files** icon in the left sidebar of the room opens an upload panel. Upload
`/tmp/pe.bundle`. It lands at `/uploads/<your-username>/pe.bundle`.

### 3c. Clone from it, on the chamber

In your compute-node shell:

```bash
mkdir -p /projects/library/$USER
cd /projects/library/$USER
ls -lh /uploads/$USER/pe.bundle
git clone /uploads/$USER/pe.bundle pe-apprentice
ln -s /projects/library/$USER/pe-apprentice ~/pe-apprentice
cd ~/pe-apprentice
git log -1 --oneline
git checkout -b $USER
```

Two things happened there. The repo lives on the project volume, which is the
one we were given and where run output belongs; your home directory is small
and may be cleaned up. And `~/pe-apprentice` is a link to it, so every path in
every week's README still works.

`git clone` on a bundle works exactly like cloning a URL. You now have a real
repository with full history that happens to have no live remote. The branch
you just created is where your work goes.

### 3d. Getting updates later

When a lead ships a fix, you get another bundle rather than the whole repo
again. Same upload, then:

```bash
cd ~/pe-apprentice
git fetch /uploads/$USER/update-weekN.bundle main:update-weekN
git merge update-weekN
```

## 4. Load the tools

```bash
source ~/pe-apprentice/setup.sh
```

It prints where each tool was found. Every tool line should show a path:

```
pe-apprentice environment loaded on sj24lo08
  genus   /apps/GENUS211/21.17.000/tools/bin/genus
  innovus /apps/INNOVUS211/21.19.000/bin/innovus
  xrun    /apps/XCELIUM2403/24.03.013/tools/bin/64bit/xrun
  assura  /apps/ASSURA41/04.16.111/tools/bin/assura
  tempus  /apps/SSV211/21.15.000/bin/tempus
  klayout /grid/common/pkgs/klayout/latest/bin/klayout
  license 5280@sj24ut01
  GSCLIB  /process/hosted/gpdk/gpdk045/ip_libraries/gsclib045/v4p4/gsclib045
  work    /projects/library/<you>
```

If a tool line says `MISSING`, `exit`, `srun --pty bash` again to get a
different node and try again. If it still says `MISSING`, get a lead.

If the `GSCLIB` line says `MISSING`, that is expected until Cadence installs
the kit; it blocks weeks 6, 7, 9 and 10 and a lead already knows.

Source this every session, after step 2.

## 5. Check that it works

```bash
cd ~/pe-apprentice/week03-rtl
xrun -sv ../rtl/fxp.sv ../rtl/pe.sv ../rtl/pe_smoke_tb.sv
```

This runs the week 3 test against the empty `pe.sv` you have not written yet, so
**it is supposed to fail its checks.** What matters is that you see a test report
at the end. If you do, your simulator works and you are set up.

If the tool refuses to start and mentions a **license**, that is not something
you can fix. Copy the exact message and send it to a lead.

## 6. Turning in work

Getting files **off** the chamber is not the reverse of getting them on. The
Files panel uploads; it does not download, and there is no SFTP. The route
out is the one part of this document most likely to change. **Ask a lead
before your first submission.**

For code, package your commits into a bundle so it is ready when the route is:

```bash
cd ~/pe-apprentice
git add <the files that week's README tells you to>
git commit -m "week 3: pe.sv"
git bundle create /projects/library/$USER/$USER-week3.bundle main..$USER
```

Reports and other small text can also be pasted: open them with `less`, and
the hub's clipboard icon (left sidebar) moves text between the chamber and
your laptop.

---

## Editing files on the chamber

There is no VS Code here. You edit with `vi`, and you only need six things.

```bash
vi somefile.txt
```

| Key | What it does |
|---|---|
| `i` | start typing (insert mode) |
| `Esc` | stop typing (back to command mode) |
| `:w` | save |
| `:q` | quit |
| `:wq` | save and quit |
| `:q!` | quit and throw away your changes |

The one rule: **`Esc` first, then the colon command.** If typing `:wq` puts the
letters into your file instead of saving it, you were still in insert mode. Press
`Esc` and try again.

To read a file without risking editing it, use `less` instead:

```bash
less timing_postroute.rpt
```

`less` scrolls with arrow keys or space, searches with `/word`, and quits with
`q`. Use `less` for reports and logs, `vi` only when you actually need to change
something.

---

## If something breaks

| What you see | What to do |
|---|---|
| `command not found` for genus, xrun, innovus | You forgot `source ~/pe-apprentice/setup.sh`, or you are still on the login node in `csh`. `srun --pty bash` first. |
| `module: Command not found` | You are in `csh` on the login node. `srun --pty bash`, then source. |
| A tool says `MISSING` in the setup output | `exit`, `srun --pty bash`, then source again |
| Anything about a license, `EXCLUDE list`, `LMF-` | Send a lead the exact message. Not yours to fix. |
| `srun` hangs with `job queued and waiting for resources` | The farm is full. Wait, or `Ctrl-C` and try later. `sinfo` shows node states. |
| `DISPLAY not set`, or a GUI will not open | Open the Terminal from the KDE desktop, not from somewhere else, and `srun --pty bash` from inside it. If it still fails, ask a lead. |
| Disk full, or writes failing strangely | `df -h /projects/library`. The volume is 190 GB for everyone. Delete old tool output from week folders you have finished. |
| You need to edit a file and there is no editor you know | See above. |
