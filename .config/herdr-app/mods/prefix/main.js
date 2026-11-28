// tmux-style prefix (C-a). keys.json opens this popup; the next key picks an action.
// Mirrors ~/.config/tmux/tmux.conf. Resize and agent-cycle keys repeat, like `bind -r`.
import { View, div } from "gpui-kit";
import { v_flex, h_flex, InputState, Input } from "gpui-base";
import { run, props, closeOverlay, openOverlay, theme, spaces, panes, agents, terminals, focused, exec, hc, home, shared, setShared, notify, nextCommand, layout } from "herdr";

const REPEAT_MS = 700;
const HOLD = "hold"; // terminal label: parked agents, skipped by C-a y
const SHIFTED = { "[": "{", "]": "}", "9": "(", "0": ")", "/": "?", "-": "_", "=": "+" };
const say = (title, level = "info", body) => notify({ title, body, level, timeout: 4000 });
const inside = (path, dir) => path === dir || path.startsWith(`${dir}/`);

// One spelling per key: "H", "}", "ctrl-a", "tab", "left"
function symbol(e) {
  const m = e.modifiers ?? {};
  if (m.control || e.keystroke?.startsWith("ctrl-")) return `ctrl-${e.key}`;
  if (e.key_char?.length === 1 && e.key_char > " ") return e.key_char;
  if (m.shift && e.key.length === 1) return SHIFTED[e.key] ?? e.key.toUpperCase();
  return e.key;
}

const space = () => spaces().find((s) => s.active);
const tab = () => space()?.tabs.find((t) => t.active);
const held = (address) => terminals().find((t) => t.address === address)?.labels?.[HOLD] === "1";

function goSpace(name, folder, argv) {
  const s = spaces().find((x) => x.name === name && !x.machine);
  if (s) return run("space.select", { id: s.id });
  run("space.new", { name, folder, machine: "", ...(argv ? { argv } : {}) });
}

// Jump to a named tab in this space, or back to the one we came from
function toggleApp(name, argv) {
  const s = space(), now = tab();
  if (!s || !now) return;
  const back = shared("prefix.back") ?? {};
  if (now.name === name) {
    const id = s.tabs.find((t) => t.id === back[s.id])?.id ?? s.tabs.find((t) => t.id !== now.id)?.id;
    return id && run("tab.select", { id });
  }
  setShared("prefix.back", { ...back, [s.id]: now.id });
  const there = s.tabs.find((t) => t.name === name);
  if (there) run("tab.select", { id: there.id });
  else run("tab.new", { name, argv });
}

function toggleBottom() {
  const mine = panes().filter((p) => p.tab === tab()?.id);
  const at = mine.find((p) => p.focused) ?? mine[0], last = mine.at(-1);
  if (mine.length < 2) return run("pane.split", { direction: "down" });
  if (at.pane === last.pane) return run("pane.zoom", { pane: mine.at(-2).pane });
  if (mine.some((p) => p.zoomed)) run("pane.zoom", { pane: at.pane });
  run("pane.focus", { pane: last.pane });
}

function cycleAgent(step) {
  const list = agents().filter((a) => a.space === space()?.id);
  if (!list.length) return say("No agents in this space");
  const i = list.findIndex((a) => a.focused);
  run("agent.focus", { terminal: list[(i < 0 ? (step > 0 ? 0 : list.length - 1) : i + step + list.length) % list.length].address });
}

// Blocked before done, longest-waiting first; held agents are skipped
function nextWaiting() {
  const rank = { blocked: 0, done: 1 };
  const list = agents().filter((a) => a.status in rank && !held(a.address)).sort((a, b) => rank[a.status] - rank[b.status] || a.seq - b.seq);
  if (!list.length || (list.length === 1 && list[0].focused)) return say("No other agents waiting");
  run("agent.focus", { terminal: list[(list.findIndex((a) => a.focused) + 1) % list.length].address });
}

function toggleHold() {
  const mine = agents().filter((a) => a.tab === tab()?.id);
  const a = mine.find((x) => x.focused) ?? mine[0];
  if (!a) return say("No agent in this tab");
  const on = !held(a.address);
  hc(["label", a.address, `${HOLD}=${on ? "1" : ""}`]).then((r) =>
    r.code === 0 ? say(on ? "Agent on hold" : "Agent released") : say("Hold failed", "error", r.stderr));
}

// Same as the tab bar's Files / Changes buttons
function togglePanel(view) {
  const find = (n, id) => (n?.id === id ? n : (n?.children ?? []).reduce((hit, c) => hit ?? find(c, id), undefined));
  const panel = find(layout(), "panel"), body = find(panel, "panel-body");
  if (!body) return say("This layout has no Files or Changes panel");
  if (!panel.hidden && body.active === view) return run("layout.hide", { id: "panel" });
  run("layout.select", { stack: "panel-body", child: view });
  run("layout.show", { id: "panel" });
}

async function git(cwd, ...args) {
  const r = await exec("git", ["-C", cwd, ...args]);
  return r.code === 0 ? r.stdout.trim() : null;
}

async function repoAt(cwd) {
  const top = cwd && await git(cwd, "rev-parse", "--show-toplevel");
  const common = top && await git(cwd, "rev-parse", "--path-format=absolute", "--git-common-dir");
  if (!common) return null;
  const main = common.replace(/\/\.git$/, "");
  return { top, main, linked: top !== main, branch: await git(top, "branch", "--show-current") };
}

// herdr-app prints what it made, so the new space's ids are known
async function make(...args) {
  const r = await exec("herdr-app", ["do", ...args]);
  const out = r.stdout.trim() ? JSON.parse(r.stdout) : {};
  if (r.code !== 0 || out.error) throw new Error(out.error || r.stderr || "herdr-app failed");
  return out;
}

// Same rule as claude() in zsh/claude.zsh
const account = (path) => (inside(path, `${home()}/projects/sharp`) ? "work" : "personal");

async function newWorktree(cwd, branch) {
  const repo = await repoAt(cwd);
  if (!repo) throw new Error("Not in a git repository.");
  const exists = await git(repo.main, "show-ref", "--verify", `refs/heads/${branch}`) !== null;
  const r = await exec("wt", ["-C", repo.main, "switch", "--no-cd", "--format", "json", ...(exists ? [] : ["--create"]), branch], { timeout: 600_000 });
  if (r.code !== 0) throw new Error(/needs approval/.test(r.stderr) ? "Project hooks need approval: run `wt config approvals add` in the repo, then retry." : r.stderr.slice(0, 400));
  const path = JSON.parse(r.stdout).path;
  if (!path) throw new Error("wt reported no path.");
  if (account(path) !== account(repo.main)) throw new Error(`${path} would use a different Claude account than ${repo.main}.`);
  const open = panes().find((p) => p.cwd && inside(p.cwd, path) && !spaces().find((s) => s.tabs.some((t) => t.id === p.tab))?.machine);
  if (open) return run("pane.focus", { pane: open.pane });
  // Claude on top, a shell below, zoomed onto Claude (C-a b reveals the shell).
  // The space stays unnamed so the sidebar nests it under its repo.
  const made = await make("space.new", "--folder", path, "--machine", "", "--tab", "claude", "--argv", '["claude"]');
  const agent = (await panesOf(made.tab)).find((p) => p.terminal === made.terminal);
  if (!agent) return;
  await make("pane.split", "--direction", "down", "--pane", agent.pane);
  await make("pane.zoom", "--pane", agent.pane);
}

// The model can lag the command by a frame
async function panesOf(tabId) {
  for (let i = 0; i < 20; i++) {
    const mine = panes().filter((p) => p.tab === tabId);
    if (mine.length) return mine;
    await exec("sleep", ["0.1"]);
  }
  return [];
}

async function worktreeToClose() {
  const s = space(), cwd = focused()?.cwd;
  if (!s || s.machine) return null;
  const repo = await repoAt(cwd);
  if (!repo?.linked) return null;
  const tabs = new Set(s.tabs.map((t) => t.id));
  const mine = panes().filter((p) => tabs.has(p.tab));
  return { ...repo, spaces: [s.id], terminals: mine.map((p) => p.terminal).filter(Boolean), strays: mine.filter((p) => p.cwd && !inside(p.cwd, repo.top)).length };
}

// Why a worktree can't be removed, or null. Dirty ones are refused.
async function blocker(w) {
  if (!w.branch) return "detached HEAD: remove it by hand";
  if (w.strays) return "its space also has terminals outside the worktree; close those first";
  if (w.others) return "a terminal in another space is inside it";
  const dirty = await git(w.top, "status", "--porcelain");
  return dirty === null ? "git status failed" : dirty ? "uncommitted changes; commit or discard first" : null;
}

// wt keeps unmerged branches, so commits are never lost here.
async function removeWorktree(w) {
  const why = await blocker(w);
  if (why) throw new Error(`${w.branch ?? w.top}: ${why}.`);
  for (const id of w.spaces) run("space.close", { id, confirmed: true });
  const alive = () => terminals().some((t) => t.state === "live" && w.terminals.includes(t.address));
  for (let i = 0; i < 100 && alive(); i++) await exec("sleep", ["0.1"]);
  if (alive()) throw new Error(`${w.branch}: its terminals haven't stopped, so the worktree was kept.`);
  const r = await exec("wt", ["-C", w.main, "remove", w.branch, "--foreground", "--yes"], { timeout: 600_000 });
  if (r.code !== 0) throw new Error(`${w.branch}: ${r.stderr.slice(-400) || "wt remove failed."}`);
  say(`Worktree ${w.branch} removed`, "success");
}

// The open worktrees closing this space involves: itself if it is one, else the
// same repo's worktree spaces (what the sidebar nests under it), one per checkout.
async function worktreesUnder(s) {
  if (!s || s.machine) return [];
  const all = panes();
  const paneList = (x) => all.filter((p) => x.tabs.some((t) => t.id === p.tab));
  const repoOf = (x) => repoAt(paneList(x).find((p) => p.cwd)?.cwd ?? x.folder);
  const own = await repoOf(s);
  if (!own) return [];
  const local = spaces().filter((x) => !x.machine);
  const found = new Map();
  for (const x of local) {
    const r = x.id === s.id ? own : await repoOf(x);
    if (!r?.linked || r.main !== own.main || (own.linked && r.top !== own.top)) continue;
    const w = found.get(r.top) ?? { ...r, spaces: [], terminals: [], strays: 0, statuses: [] };
    const mine = paneList(x);
    w.spaces.push(x.id);
    w.terminals.push(...mine.map((p) => p.terminal).filter(Boolean));
    w.strays += mine.filter((p) => p.cwd && !inside(p.cwd, r.top)).length;
    w.statuses.push(...mine.map((p) => p.status).filter(Boolean));
    found.set(r.top, w);
  }
  const list = [...found.values()];
  for (const w of list) {
    w.others = local.filter((x) => !w.spaces.includes(x.id)).flatMap(paneList).filter((p) => p.cwd && inside(p.cwd, w.top)).length;
    w.why = await blocker(w);
  }
  return list;
}

// remove: also remove the worktrees, checked first so a blocked one stops everything.
// Otherwise only the spaces close; C-a n or C-a N opens a kept worktree again.
async function closeSpace(id, worktrees, remove) {
  if (remove) {
    for (const w of worktrees) {
      const why = await blocker(w);
      if (why) throw new Error(`Nothing was closed. ${w.branch ?? w.top}: ${why}.`);
    }
    for (const w of worktrees) await removeWorktree(w);
  } else {
    for (const x of worktrees.flatMap((w) => w.spaces)) if (x !== id) run("space.close", { id: x, confirmed: true });
  }
  if (!worktrees.some((w) => remove && w.spaces.includes(id))) run("space.close", { id, confirmed: true });
}

// Plain sh, run on each machine: projects (minus worktrunk folders), then zoxide.
// PATH is widened because a remote non-login shell may not have zoxide on it.
const LIST_DIRS = `PATH="$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
printf '%s\\n' "$HOME"
for d in "$HOME"/projects/*/ "$HOME"/projects/sharp/*/; do
  d=\${d%/}
  case "$d" in *-worktrees) continue;; esac
  if [ -d "$d" ]; then printf '%s\\n' "$d"; fi
done
zoxide query -l 2>/dev/null | head -60
exit 0`;

async function dirsOn(machine) {
  const r = await exec("sh", ["-c", LIST_DIRS], { on: machine, timeout: 10_000 });
  if (r.code !== 0) throw new Error(r.stderr || "listing failed");
  const [root, ...rest] = r.stdout.split("\n").filter(Boolean);
  return [...new Set([...rest, root])].map((path) => ({
    machine, path, name: path.split("/").at(-1),
    short: path === root ? "~" : inside(path, root) ? `~${path.slice(root.length)}` : path,
  }));
}

// This computer (null) plus connected machines, the current space's machine first
async function machineNames() {
  let names = [];
  try {
    const r = await hc(["machine", "ls", "--json"]);
    names = (JSON.parse(r.stdout).machines ?? []).filter((m) => m.state === "connected" && !m.temporary).map((m) => m.name);
  } catch {}
  const here = space()?.machine ?? null;
  return [null, ...names].sort((a, b) => (b === here) - (a === here));
}

// Each space with the folder its first terminal is in. Read once per list:
// panes() and spaces() cover every machine, so calling them per folder is too slow.
function spaceFolders() {
  const all = panes();
  return spaces().map((s) => {
    const tabs = new Set(s.tabs.map((t) => t.id));
    return { s, cwd: all.find((p) => p.cwd && tabs.has(p.tab))?.cwd };
  }).filter((f) => f.cwd);
}

function spaceAt(d, folders = spaceFolders()) {
  return folders.find(({ s, cwd }) => (s.machine ?? null) === d.machine
    && (cwd === d.path || (s.name === d.name && inside(cwd, d.path))))?.s;
}

function openDir(d) {
  if (d.tab) return run("tab.select", { id: d.tab });
  const there = spaceAt(d);
  if (there) run("space.select", { id: there.id });
  else run("space.new", { folder: d.path, machine: d.machine ?? "" });
}

// One row per open tab, the shown one last so Enter goes somewhere else.
// `text` is what a search sees: every pane's folder and branch, plus names.
function openTabs() {
  const all = panes();
  const rows = spaces().flatMap((s) => s.tabs.map((t) => {
    const mine = all.filter((p) => p.tab === t.id);
    const cwd = (mine.find((p) => p.focused) ?? mine.find((p) => p.cwd))?.cwd ?? s.folder ?? "";
    const tidy = (path) => path.replace(/^\/(home|Users)\/[^/]+/, "~");
    return {
      tab: t.id, machine: s.machine ?? null, path: cwd, name: s.name, status: t.status,
      label: s.tabs.length > 1 || t.named ? `${s.name} · ${t.name}` : s.name,
      short: tidy(cwd), branch: mine.find((p) => p.branch)?.branch ?? "",
      text: [s.name, t.name, ...mine.flatMap((p) => [tidy(p.cwd ?? ""), p.branch ?? "", p.title ?? ""])].join(" "),
      here: s.active && t.active,
    };
  }));
  return [...rows.filter((r) => !r.here), ...rows.filter((r) => r.here)];
}

// Every typed word must appear; matches on the folder's own name come first
function matchDirs(dirs, query) {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  const hit = (text) => words.every((w) => text.toLowerCase().includes(w));
  const all = dirs.filter((d) => hit(`${d.text ?? ""} ${d.short} ${d.machine ?? "local"}`));
  if (!words.length) return all;
  const rank = (d) => (d.tab ? 0 : 2) + (hit(d.name) ? 0 : 1);
  return all.map((d, i) => [rank(d), i, d]).sort((a, b) => a[0] - b[0] || a[1] - b[1]).map((x) => x[2]);
}

const go = (name, args) => () => run(name, args ?? {});
const KEYS = {
  "\\": ["split right", go("pane.split", { direction: "right" })],
  "-": ["split down", go("pane.split", { direction: "down" })],
  w: ["close pane", go("pane.close")],
  m: ["zoom", go("pane.zoom")],
  b: ["bottom pane", toggleBottom],
  t: ["new tab", go("tab.new")],
  "[": ["prev tab", go("tab.prev")],
  "]": ["next tab", go("tab.next")],
  n: ["new worktree", "branch"],
  W: ["close tab / worktree", "close"],
  o: ["go to space / dir", "spaces"],
  N: ["new space in…", "dirs"],
  d: ["main space", () => goSpace("main", home())],
  k: ["k8s space", () => goSpace("k8s", home(), ["kubectl", "proxy"])],
  R: ["rename space", go("space.rename")],
  "(": ["prev space", go("space.prev")],
  ")": ["next space", go("space.next")],
  tab: ["last space", () => { const id = shared("prefix.last"); if (id) run("space.select", { id }); }],
  X: ["close space", "closeSpace"],
  a: ["claude tab", () => toggleApp("claude", ["claude"])],
  y: ["next waiting agent", nextWaiting],
  Y: ["agent 1-9", "agent"],
  A: ["agent picker", go("mod.open", { name: "picker" })],
  h: ["hold agent", toggleHold],
  "{": ["prev agent here", () => cycleAgent(-1), true],
  "}": ["next agent here", () => cycleAgent(1), true],
  S: ["sidebar", go("layout.toggle", { id: "sidebar" })],
  f: ["files panel", () => togglePanel("files")],
  g: ["changes panel", () => togglePanel("changes")],
  "?": ["all shortcuts", go("app.help")],
  "ctrl-a": ["send C-a", "literal"],
  "ctrl-l": ["send C-l", "literal"],
};
for (const [key, direction] of [["H", "left"], ["J", "down"], ["K", "up"], ["L", "right"]]) {
  KEYS[key] = [`resize ${direction}`, go("pane.resize", { direction }), true];
  KEYS[direction] = [`go ${direction}`, go("pane.go", { direction })];
}

export default class Prefix extends View {
  init(_props, cx) {
    this.mode = "keys";
    this.error = "";
    this.gen = 0;
    this.cwd = focused()?.cwd ?? null;
    this.terminal = focused()?.terminal ?? null;
    this.handle = cx.focus_handle();
    this.handle.focus();
    // keys.json sends C-a here while the popup is open ("mod:prefix")
    cx.spawn(async (cx) => {
      for (;;) {
        const c = await nextCommand();
        if (c === "literal" && this.mode === "keys") this.literal("ctrl+a");
        else if (c === "dirs" || c === "spaces") this.askDir(cx, c === "spaces");
      }
    });
    // Remember the previous space for C-a Tab
    const id = space()?.id;
    if (id && shared("prefix.current") !== id) {
      setShared("prefix.last", shared("prefix.current") ?? null);
      setShared("prefix.current", id);
    }
  }

  close() { closeOverlay(props().overlay); }

  fail(error, cx) { this.mode = "error"; this.error = String(error?.message ?? error); this.handle.focus(); cx.notify(); }

  work(cx, label, task) {
    this.mode = "busy"; this.error = label; cx.notify();
    cx.spawn(async (cx) => { try { await task(); this.close(); } catch (e) { this.fail(e, cx); } });
  }

  key(e, cx) {
    if (this.mode === "dirs") return this.dirKey(e, cx);
    if (this.mode === "branch" && e.key !== "escape") return; // the input has it
    cx.stop_propagation();
    if (e.key === "escape") return this.close();
    if (this.mode === "busy") return;
    if (this.mode === "error") return this.close();
    const k = symbol(e);
    if (this.mode === "agent") { this.close(); return /^[1-9]$/.test(k) && run("agent.select", { index: Number(k) }); }
    if (this.mode === "remove") return k === "y" ? this.work(cx, "Removing worktree…", () => removeWorktree(this.target)) : this.close();

    if (this.mode === "removeAll") {
      if (k === "y" && !this.targets.some((w) => w.why)) return this.work(cx, "Removing worktrees…", () => closeSpace(this.spaceId, this.targets, true));
      if (k === "n") return this.work(cx, "Closing…", () => closeSpace(this.spaceId, this.targets, false));
      return k === "y" ? undefined : this.close();
    }

    const action = KEYS[k];
    if (!action) return this.close();
    const [, what, repeat] = action;
    if (what === "agent") { this.mode = "agent"; return cx.notify(); }
    if (what === "branch") return this.askBranch(cx);
    if (what === "close") return this.askClose(cx);
    if (what === "closeSpace") return this.askCloseSpace(cx);
    if (what === "literal") return this.literal(k.replace("-", "+"));
    if (what === "dirs") return this.askDir(cx);
    if (what === "spaces") return this.askDir(cx, true);
    if (!repeat) { this.close(); return what(); }
    what();
    const gen = ++this.gen;
    this.handle.focus();
    cx.timer.after(REPEAT_MS, () => { if (gen === this.gen && this.mode === "keys") this.close(); });
  }

  literal(key) { this.close(); if (this.terminal) hc(["keys", this.terminal, key]); }

  // open: list open tabs above the folders (C-a o); without it, folders only (C-a N)
  askDir(cx, open = false) {
    this.open = open; this.only = false;
    this.mode = "dirs"; this.dirs = []; this.at = 0; this.query = ""; this.loading = true; this.notes = [];
    this.input = InputState.new({ placeholder: open ? "space, folder, branch or machine" : "project, folder or machine" });
    this.input.on("change", (_e, cx) => { this.query = this.input.value(); this.at = 0; cx.notify(); });
    this.input.on("submit", () => this.pickDir());
    this.input.focus();
    cx.timer.after(100, () => this.input.focus());
    cx.spawn(async (cx) => {
      const names = await machineNames();
      const found = await Promise.all(names.map(async (m) => {
        try { return await dirsOn(m); } catch { this.notes.push(`${m ?? "this computer"}: no folders`); return []; }
      }));
      this.dirs = found.flat(); this.loading = false; cx.notify();
    });
    cx.notify();
  }

  rows() {
    if (!this.open) return matchDirs(this.dirs, this.query);
    const tabs = openTabs();
    const folders = this.only ? [] : spaceFolders();
    const dirs = this.only ? [] : this.dirs.filter((d) => !spaceAt(d, folders));
    return matchDirs([...tabs, ...dirs], this.query);
  }

  pickDir() {
    const d = this.rows()[this.at];
    if (!d) return;
    this.close();
    openDir(d);
  }

  dirKey(e, cx) {
    const n = this.rows().length, k = symbol(e);
    if (k === "escape") { cx.stop_propagation(); return this.close(); }
    if (this.open && (k === "ctrl-s" || k === "ctrl-d")) {
      cx.stop_propagation();
      this.only = k === "ctrl-s"; this.at = 0;
      return cx.notify();
    }
    const step = k === "down" || k === "ctrl-n" ? 1 : k === "up" || k === "ctrl-p" ? -1 : 0;
    if (!step || !n) return; // the input has it
    cx.stop_propagation();
    this.at = (this.at + step + n) % n;
    cx.notify();
  }

  renderDirs(t) {
    const rows = this.rows(), size = 10;
    const from = Math.max(0, Math.min(this.at - 4, rows.length - size));
    const note = this.loading ? "Loading…" : [`${rows.length} ${this.open ? "matches" : "folders"}`, ...(this.open ? [this.only ? "ctrl-d: show all" : "ctrl-s: open only"] : []), ...this.notes].join(" · ");
    return v_flex().gap(6)
      .child(Input.new(this.input).h(34).px(10).rounded(8).border_1().border_color(t.accent).bg(t.background).text_color(t.foreground))
      .children(rows.slice(from, from + size).map((d, i) =>
        h_flex().id(`d-${from + i}`).h(22).px(8).gap(8).items_center().rounded(5).cursor_pointer()
          .bg(from + i === this.at ? t.selected : t.popover)
          .on_click(() => { this.close(); openDir(d); })
          .when(Boolean(d.tab), (el) => el
            .child(div().w(8).flex_none().text_color(t[d.status] ?? t.accent).child("●"))
            .child(div().max_w(260).flex_none().truncate().text_color(t.foreground).child(d.label))
            .child(div().flex_1().min_w(0).truncate().text_color(t.muted).child([d.short, d.branch].filter(Boolean).join("  "))))
          .when(!d.tab, (el) => el
            .child(div().flex_1().min_w(0).truncate().text_color(this.open ? t.muted : t.foreground).child(d.short)))
          .child(div().flex_none().text_color(t.dim).child(d.machine ?? "this computer"))))
      .child(div().text_size(11).text_color(t.dim).child(note));
  }

  askBranch(cx) {
    const s = space();
    // Other machines have their own worktree setup: use Herdr's dialog there
    if (s?.machine) { this.close(); openOverlay({ mod: "worktree", kind: "dialog", width: 460, height: 300, props: { space: s.id, action: "new" } }); return; }
    this.mode = "branch";
    this.input = InputState.new({ placeholder: "branch name" });
    this.input.on("submit", (_e, cx) => {
      const branch = this.input.value().trim();
      if (branch) this.work(cx, `Creating ${branch}…`, () => newWorktree(this.cwd, branch));
    });
    this.input.focus();
    cx.timer.after(100, () => this.input.focus());
    cx.notify();
  }

  askClose(cx) {
    this.mode = "busy"; this.error = "…"; cx.notify();
    cx.spawn(async (cx) => {
      try {
        this.target = await worktreeToClose();
        if (!this.target) { this.close(); run("tab.close"); return; }
        this.mode = "remove";
        this.handle.focus();
        cx.notify();
      } catch (e) { this.fail(e, cx); }
    });
  }

  askCloseSpace(cx) {
    const s = space();
    if (!s) return this.close();
    this.mode = "busy"; this.error = "Checking for worktrees…"; cx.notify();
    cx.spawn(async (cx) => {
      try {
        this.spaceId = s.id; this.spaceName = s.name;
        this.targets = await worktreesUnder(s);
        if (!this.targets.length) { this.close(); run("space.close", { id: s.id }); return; }
        this.mode = "removeAll";
        this.handle.focus();
        cx.notify();
      } catch (e) { this.fail(e, cx); }
    });
  }

  renderRemoveAll(t, text) {
    const blocked = this.targets.some((w) => w.why);
    return v_flex().gap(8)
      .child(text(`Close ${this.spaceName}: also remove ${this.targets.length === 1 ? "its worktree" : `its ${this.targets.length} worktrees`}?`))
      .children(this.targets.slice(0, 8).map((w) => h_flex().gap(8)
        .child(text(w.branch ?? "(detached)", t.accent))
        .child(text(w.why ?? "clean", w.why ? t.blocked : t.muted))
        .when(w.statuses.some((x) => x === "working" || x === "blocked"), (el) => el.child(text("agent still busy", t.working)))))
      .when(this.targets.length > 8, (el) => el.child(text(`and ${this.targets.length - 8} more`, t.dim)))
      .child(text(blocked ? "y  unavailable until the above is resolved" : "y  remove worktrees and close their spaces", blocked ? t.dim : t.foreground))
      .child(text("n  close the spaces, keep the worktrees on disk"))
      .child(text("Esc  cancel", t.dim));
  }

  render() {
    const t = theme();
    const text = (s, c = t.foreground) => div().text_color(c).child(s);
    const body = v_flex().id("prefix").track_focus(this.handle).on_key_down((e, cx) => this.key(e, cx))
      .size_full().p(14).gap(8).bg(t.popover).text_size(12.5)
      .child(div().font_semibold().text_color(t.accent).child("C-a"));
    if (this.mode === "dirs") return body.child(this.renderDirs(t));
    if (this.mode === "branch") return body.child(text("New worktree branch (worktrunk, opens Claude + shell)"))
      .child(Input.new(this.input).h(34).px(10).rounded(8).border_1().border_color(t.accent).bg(t.background).text_color(t.foreground));
    if (this.mode === "agent") return body.child(text("Agent number: 1-9"));
    if (this.mode === "busy") return body.child(text(this.error, t.muted));
    if (this.mode === "error") return body.child(text(this.error, t.blocked)).child(text("Any key closes", t.dim));
    if (this.mode === "removeAll") return body.child(this.renderRemoveAll(t, text));
    if (this.mode === "remove") return body.child(text(`Remove worktree ${this.target.branch ?? "(detached)"} and close its space? (y/n)`));
    return body.child(h_flex().flex_wrap().children(Object.entries(KEYS).map(([k, [label]]) =>
      h_flex().w(190).h(22).gap(8).child(div().w(52).text_color(t.accent).child(k)).child(text(label, t.muted)))));
  }
}
