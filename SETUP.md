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

```
% bash
% qsh -q normal.q -now n -V
% bash
```

Your prompt should now show something like `ip-10-2-6-219`. That is how you know
it worked.

**Do this every time you log in.** Every command in every week assumes it.

## 3. Get the repo

The chamber cannot reach GitHub, so the repo travels as a single file called a
bundle.

On your laptop:

```
% git clone git@github.com:LonghornSilicon/pe-apprentice.git
% cd pe-apprentice
% git bundle create pe-apprentice.bundle --all
```

Move `pe-apprentice.bundle` to the chamber using the ETX file transfer panel.
Then on the chamber:

```
% cd ~
% git clone pe-apprentice.bundle pe-apprentice
% cd pe-apprentice
% git checkout -b <your-username>
```

## 4. Load the tools

```
% source ~/pe-apprentice/setup.sh
```

It prints where each tool was found. Every line should show a path:

```
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

```
% cd ~/pe-apprentice/week03-rtl
% xrun -sv ../rtl/fxp.sv ../rtl/pe.sv ../rtl/pe_smoke_tb.sv
```

This runs the week 3 test against the empty `pe.sv` you have not written yet, so
**it is supposed to fail its checks.** What matters is that you see a test report
at the end. If you do, your simulator works and you are set up.

If the tool refuses to start and mentions a **license**, that is not something
you can fix. Copy the exact message and send it to a lead.

## 6. Turning in work

Written work (photos or scans of your handwritten weeks) and code both leave the
chamber the same way. **Ask a lead for the current route before your first
submission.**

For code, package your commits into a bundle:

```
% cd ~/pe-apprentice
% git add <the files that week's README tells you to>
% git commit -m "week 3: pe.sv"
% git bundle create ~/<your-username>-week3.bundle main..<your-username>
```

Then move that bundle off the chamber.

---

## If something breaks

| What you see | What to do |
|---|---|
| `command not found` for genus, xrun, innovus | You forgot `source ~/pe-apprentice/setup.sh` |
| A tool says `MISSING` in the setup output | `qsh -q normal.q -now n -V`, then source again |
| Anything about a license | Send a lead the exact message. Not yours to fix. |
| `DISPLAY not set`, or a GUI will not open | Your X11 is not forwarding. Ask a lead. |
| Disk full, or writes failing strangely | `df -h ~`. You get 20 GB. Delete old tool output from week folders you have finished. |
