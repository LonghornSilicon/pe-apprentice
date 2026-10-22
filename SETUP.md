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
srun -c 4 --mem=16G --pty bash
```

Your prompt changes to another `sj24loNN` and you are in `bash`. That is how
you know it worked.

The two flags matter. Slurm gives each job a slice of one node: some cores
and some memory. Without `--mem`, this chamber hands your job **all** the
memory on the node, and nobody else can use that node until you leave, even
though you are using one core. 4 cores and 16 GB is plenty for every week in
this program and lets six or more people share one machine.

**Do this every time you log in.** Every command in every week assumes it.

Two Slurm habits:

- `exit` when you are done. Your slice of the node is held until you leave.
- `squeue -u <your-username>` lists what you have running. If you closed a browser tab
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
**Files** icon in the left sidebar of the room opens an upload panel. The
panel refuses `.bundle` files, so rename first:

```bash
mv /tmp/pe.bundle /tmp/pe.txt
```

Upload `/tmp/pe.txt`. It lands at `/uploads/<your-username>/pe.txt`. git
does not care what the file is called.

### 3c. Copy it to the project volume

`/uploads` is read-only and only the **login node** can see it. So before
you `srun`, still on `sj24lo04`:

```bash
mkdir -p /projects/library/<your-username>
cp /uploads/<your-username>/pe.txt /projects/library/<your-username>/pe.bundle
ls -lh /projects/library/<your-username>/
```

The project volume is the one we were given, every node can see it, and it
is where run output belongs. Your home directory is small and may be cleaned
up.

### 3d. Clone from it, on a compute node

```bash
srun -c 4 --mem=16G --pty bash
cd /projects/library/<your-username>
git clone pe.bundle pe-apprentice
ln -s /projects/library/<your-username>/pe-apprentice ~/pe-apprentice
cd ~/pe-apprentice
git log -1 --oneline
git checkout -b <your-username>
```

`~/pe-apprentice` is now a link to the project volume, so every path in every
week's README works unchanged. `git clone` on a bundle works exactly like
cloning a URL: a real repository with full history and no live remote. The
branch you just created is where your work goes.

Where everything ends up:

```
/projects/library/<you>/            your directory, on the 190 GB project disk
├── pe.bundle                       the repo as one file, copied from /uploads
└── pe-apprentice/                  the repo; ~/pe-apprentice points here
    ├── setup.sh                    loads the tools; source it every session
    ├── rtl/                        pe.sv, fxp.sv, the vendor drop
    ├── week03-rtl/                 tool output lands in the week you launch from
    ├── week05-verification/
    └── week09-pnr/work/            big runs go in work/, which git ignores

/home/<you>/                        small, may be purged; holds only the link
└── pe-apprentice -> /projects/library/<you>/pe-apprentice

/uploads/<you>/                     read-only inbox, login node only
/tmp, /scratch                      local to one node, gone when you change node
```

### 3e. Getting updates later

When a lead ships a fix, you get another bundle rather than the whole repo
again. Same upload and copy, then:

```bash
cd ~/pe-apprentice
git fetch /projects/library/<your-username>/update-weekN.bundle main:update-weekN
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

If a tool line says `MISSING`, `exit`, `srun` again (section 2) to get a
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
git bundle create /projects/library/<your-username>/<your-username>-week3.bundle main..<your-username>
```

Reports and other small text can also be pasted: open them with `less`, and
the hub's clipboard icon (left sidebar) moves text between the chamber and
your laptop.

Never leave a job's only copy in `/tmp`: it is local to one node and gone
when the node is reimaged.

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
| `command not found` for genus, xrun, innovus | You forgot `source ~/pe-apprentice/setup.sh`, or you are still on the login node in `csh`. `srun` first (section 2). |
| `module: Command not found` | You are in `csh` on the login node. `srun` (section 2), then source. |
| A tool says `MISSING` in the setup output | `exit`, `srun` again (section 2), then source again |
| `User/host on EXCLUDE list`, `LMF-` | You ran the tool on the login node. `srun` first (section 2); the login node is not allowed to check out licenses. If it happens on a compute node, send a lead the exact message. |
| `/uploads/...: No such file or directory` | You are on a compute node. `/uploads` exists only on the login node; use the copy in `/projects/library`. |
| The Files panel refuses your file | It filters on extension. Rename to `.txt`; the contents do not matter. |
| `genus.log`, `innovus.cmd`, `xrun.history` piling up in your home | Tools write logs where you launch them. Launch from the week's `work` directory, never from `~`. |
| `srun` hangs with `job queued and waiting for resources` | The farm is full. Wait, or `Ctrl-C` and try later. `sinfo` shows node states. |
| `DISPLAY not set`, or a GUI will not open | Open the Terminal from the KDE desktop, not from somewhere else, and `srun` (section 2) from inside it. If it still fails, ask a lead. |
| Disk full, or writes failing strangely | `df -h /projects/library`. The volume is 190 GB for everyone. Delete old tool output from week folders you have finished. |
| You need to edit a file and there is no editor you know | See above. |
