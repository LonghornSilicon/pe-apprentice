# Setup

Do this once, before week 2. It takes about an hour.

You need: a Cadence chamber account from a lead (this is not your UT EID, it is
a separate username and password), and the UT Austin VPN connected.

If anything below does not work the way it says, stop and ask a lead. Do not
improvise. The chamber is shared with other universities.

---

## 1. Log in

Connect to the UT VPN, then open the ETX portal in your browser (a lead gives
you the URL) and log in with your chamber username and password.

You land on a machine called `ae03ut01`. That is the login node.

## 2. Get onto a compute node

The login node is shared and slow. Real work goes on a compute node.

```bash
bash
qsh -q normal.q -now n -V
bash
```

Your prompt should now show something like `ip-10-2-6-219`. That is how you know
it worked.

**Do this every time you log in.** Every command in every week assumes it.

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

### 3b. Connect over SFTP

You must be on the **UT Austin VPN**. The chamber is on a private network and
nothing below resolves without it.

```bash
sftp -P 222 \
     -o HostKeyAlgorithms=+ssh-rsa \
     -o PubkeyAcceptedAlgorithms=+ssh-rsa \
     <your-chamber-username>@10.2.6.6
```

Four things in that command, and you need all of them:

- **`-P 222`** is a capital P. SFTP is on port 222, not the usual 22. Lowercase
  `-p` means something else entirely and will not work.
- **`10.2.6.6`** is the file-transfer address. It is not `ae03ut01`, which is
  the name of the login node you see inside ETX.
- **`HostKeyAlgorithms=+ssh-rsa`** and **`PubkeyAcceptedAlgorithms=+ssh-rsa`**
  re-enable an older key algorithm. OpenSSH 8.8 and later turn `ssh-rsa` off by
  default, and the chamber runs RHEL 7 which only offers it. Without these two
  flags a recent macOS or Linux machine fails with
  `no matching host key type found`, which sounds like a network problem and is
  not.

First connection warns about an unknown host key. Type `yes`. If you ever see
that warning again on a later connection, stop and get a lead; do not type `yes`
a second time.

Then your chamber password, and you land at:

```
sftp>
```

### 3c. Upload

```
sftp> pwd
sftp> put /tmp/pe.bundle
sftp> ls -l pe.bundle
sftp> bye
```

`pwd` shows your remote directory, which is your chamber home. `put` sends the
file there. `ls -l` confirms the size matches what you saw on your laptop; if it
is smaller, the transfer was cut short and you should re-send.

**The chamber's SFTP is create-only.** You can write a file that does not exist.
You cannot overwrite one that does, and you cannot delete. If you need to send a
corrected bundle, give it a different name:

```
sftp> put /tmp/pe.bundle pe-v2.bundle
```

This is also why bundles are named with a timestamp or commit hash in any
automated setup: every push produces a filename that has never existed.

### 3d. Clone from it, on the chamber

Back in ETX:

```bash
cd ~
ls -lh pe.bundle
git clone pe.bundle pe-apprentice
cd pe-apprentice
git log -1 --oneline
git checkout -b <your-chamber-username>
```

`git clone` on a bundle works exactly like cloning a URL. You now have a real
repository with full history that happens to have no live remote. The branch you
just created is where your work goes.

### 3e. Getting updates later

When a lead ships a fix, you get another bundle rather than the whole repo
again. Same `put`, then:

```bash
cd ~/pe-apprentice
git fetch ~/update-weekN.bundle main:update-weekN
git merge update-weekN
```

### Windows

`sftp` ships with macOS and Linux. On Windows use the OpenSSH client in
PowerShell, which takes the same flags, or WinSCP with port 222 and the same
host.

## 4. Load the tools

```bash
source ~/pe-apprentice/setup.sh
```

It prints where each tool was found. Every line should show a path:

```bash
pe-apprentice environment loaded
  genus   /apps/GENUS211/21.18.000/tools/bin/genus
  innovus /apps/INNOVUS211/21.18.000/bin/innovus
  xrun    /apps/XCELIUM2403/24.03.005/tools/bin/xrun
  assura  /apps/ASSURA41/04.17.001-618/tools/bin/assura
```

If any line says `MISSING`, run `qsh -q normal.q -now n -V` to get a different
compute node and try again. If it still says `MISSING`, get a lead.

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
same SFTP connection that accepts `put` has historically refused `get`, so the
route out is the one part of this document most likely to have changed. **Ask a
lead before your first submission.**

If `get` is working, it is the same connection as section 3b:

```bash
sftp -P 222 -o HostKeyAlgorithms=+ssh-rsa \
     -o PubkeyAcceptedAlgorithms=+ssh-rsa \
     <your-chamber-username>@10.2.6.6
```

```
sftp> get <your-username>-week3.bundle
sftp> bye
```

If it refuses, ETX has a file-transfer panel, and a lead will show you.

For code, package your commits into a bundle:

```bash
cd ~/pe-apprentice
git add <the files that week's README tells you to>
git commit -m "week 3: pe.sv"
git bundle create ~/<your-username>-week3.bundle main..<your-username>
```

Then move that bundle off the chamber.

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
| `command not found` for genus, xrun, innovus | You forgot `source ~/pe-apprentice/setup.sh` |
| A tool says `MISSING` in the setup output | `qsh -q normal.q -now n -V`, then source again |
| Anything about a license | Send a lead the exact message. Not yours to fix. |
| `DISPLAY not set`, or a GUI will not open | Your X11 is not forwarding. Ask a lead. |
| Disk full, or writes failing strangely | `df -h ~`. You get 20 GB. Delete old tool output from week folders you have finished. |
| You need to edit a file and there is no editor you know | See below. |
