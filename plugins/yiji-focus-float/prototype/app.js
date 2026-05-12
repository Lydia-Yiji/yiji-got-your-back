const STORAGE_KEY = "yiji-focus-float.v2";
const INACTIVITY_MS = 30 * 60 * 1000;
const HEARTBEAT_MS = 30 * 1000;

const CATEGORIES = [
  { key: "reading", label: "读文献", accent: "moss" },
  { key: "cleaning", label: "洗数据", accent: "blue" },
  { key: "modeling", label: "做模型", accent: "berry" },
  { key: "writing", label: "写论文", accent: "gold" },
  { key: "fun", label: "娱乐", accent: "pink" },
  { key: "food", label: "饭饭", accent: "orange" },
  { key: "exercise", label: "运动", accent: "green" },
  { key: "family", label: "家庭生活", accent: "lavender" }
];

const CATEGORY_MAP = Object.fromEntries(CATEGORIES.map((category) => [category.key, category]));

const ENCOURAGEMENTS = [
  {
    threshold: 0,
    message: "今天还没开始记也没关系，双击一姬，先收下第一块小砖。"
  },
  {
    threshold: 1,
    message: "已经有进度了，今天不是空白页，一姬看见了。"
  },
  {
    threshold: 3,
    message: "今天的日程线已经很漂亮了，你真的在把事情一块块搬走。"
  },
  {
    threshold: 5,
    message: "今天硕果累累，一姬申请把你夸成最佳铲屎官兼最强行动派。"
  }
];

const state = loadState();
let pendingReminder = null;
let lastActivityStamp = state.lastActivityAt ? new Date(state.lastActivityAt).getTime() : 0;
let activityWriteStamp = lastActivityStamp;

const petToggle = document.getElementById("pet-toggle");
const activeState = document.getElementById("active-state");
const activeTaskEl = document.getElementById("active-task");
const summaryCount = document.getElementById("summary-count");
const summaryMinutes = document.getElementById("summary-minutes");
const summaryLongest = document.getElementById("summary-longest");
const timelineEl = document.getElementById("timeline");
const encouragementEl = document.getElementById("encouragement");
const weeklyEl = document.getElementById("weekly-report");
const stopDialog = document.getElementById("stop-dialog");
const stopTitle = document.getElementById("stop-dialog-title");
const stopForm = document.getElementById("stop-form");
const outcomeInput = document.getElementById("task-outcome");
const feelingInput = document.getElementById("task-feeling");
const cancelStop = document.getElementById("cancel-stop");
const exportButton = document.getElementById("export-json");
const resetButton = document.getElementById("reset-day");
const startDialog = document.getElementById("start-dialog");
const startOptions = document.getElementById("start-options");
const cancelStart = document.getElementById("cancel-start");
const reminderCard = document.getElementById("reminder-card");
const reminderTitle = document.getElementById("reminder-title");
const reminderBody = document.getElementById("reminder-body");

petToggle.addEventListener("dblclick", onPetDoubleClick);
cancelStop.addEventListener("click", () => stopDialog.close("cancel"));
stopForm.addEventListener("submit", onStopSubmit);
exportButton.addEventListener("click", exportToday);
resetButton.addEventListener("click", resetToday);
cancelStart.addEventListener("click", () => startDialog.close("cancel"));
startOptions.addEventListener("click", onStartOptionClick);

[
  "pointerdown",
  "keydown",
  "wheel",
  "mousemove",
  "focus",
  "visibilitychange"
].forEach((eventName) => {
  window.addEventListener(eventName, onUserActivity, { passive: true });
});

setInterval(tick, HEARTBEAT_MS);
render();
tick();

function loadState() {
  const fallback = {
    activeTask: null,
    days: {},
    lastActivityAt: null
  };

  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      return fallback;
    }
    const parsed = JSON.parse(raw);
    return {
      activeTask: parsed.activeTask || null,
      days: parsed.days || {},
      lastActivityAt: parsed.lastActivityAt || null
    };
  } catch {
    return fallback;
  }
}

function saveState() {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
}

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

function getDayEntries(dayKey) {
  if (!state.days[dayKey]) {
    state.days[dayKey] = [];
  }
  return state.days[dayKey];
}

function getTodayEntries() {
  return getDayEntries(todayKey());
}

function onPetDoubleClick() {
  trackActivity(true);

  if (pendingReminder) {
    pendingReminder = null;
    renderReminder();
    return;
  }

  if (state.activeTask) {
    openStopDialog();
    return;
  }

  startDialog.showModal();
}

function onStartOptionClick(event) {
  const button = event.target.closest("[data-category]");
  if (!button) {
    return;
  }

  const categoryKey = button.dataset.category;
  const category = CATEGORY_MAP[categoryKey];
  if (!category) {
    return;
  }

  const nowIso = new Date().toISOString();
  state.activeTask = {
    id: `task-${Date.now()}`,
    category: category.key,
    label: category.label,
    accent: category.accent,
    startTime: nowIso,
  };
  state.lastActivityAt = nowIso;
  lastActivityStamp = new Date(nowIso).getTime();
  activityWriteStamp = lastActivityStamp;

  saveState();
  startDialog.close("selected");
  render();
}

function openStopDialog() {
  const task = state.activeTask;
  if (!task) {
    return;
  }
  stopTitle.textContent = `${task.label} 从 ${formatTime(task.startTime)} 开始。`;
  outcomeInput.value = "";
  feelingInput.value = "";
  stopDialog.showModal();
}

function onStopSubmit(event) {
  event.preventDefault();
  if (!state.activeTask) {
    stopDialog.close();
    return;
  }

  const nowIso = new Date().toISOString();
  const active = state.activeTask;
  const entry = {
    ...active,
    endTime: nowIso,
    outcome: outcomeInput.value.trim(),
    feeling: feelingInput.value.trim()
  };

  getTodayEntries().push(entry);
  state.activeTask = null;
  state.lastActivityAt = nowIso;
  lastActivityStamp = new Date(nowIso).getTime();
  activityWriteStamp = lastActivityStamp;
  saveState();
  stopDialog.close("saved");
  render();
}

function resetToday() {
  if (!window.confirm("清空今天的记录吗？不会影响其他天。")) {
    return;
  }
  state.days[todayKey()] = [];
  if (state.activeTask && state.activeTask.startTime.slice(0, 10) === todayKey()) {
    state.activeTask = null;
  }
  pendingReminder = null;
  saveState();
  render();
}

function exportToday() {
  const payload = {
    date: todayKey(),
    activeTask: state.activeTask,
    completed: getTodayEntries()
  };
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `yiji-focus-${todayKey()}.json`;
  link.click();
  URL.revokeObjectURL(url);
}

function tick() {
  maybeRaiseReminders();
  render();
}

function onUserActivity(event) {
  if (event.type === "visibilitychange" && document.visibilityState === "hidden") {
    return;
  }

  if (event.type === "mousemove" && Date.now() - lastActivityStamp < 15000) {
    return;
  }

  trackActivity(false);
}

function trackActivity(forceWrite) {
  if (document.visibilityState === "hidden") {
    return;
  }

  const now = Date.now();
  lastActivityStamp = now;

  if (!forceWrite && now - activityWriteStamp < 60000) {
    return;
  }

  activityWriteStamp = now;
  state.lastActivityAt = new Date(now).toISOString();
  saveState();
}

function maybeRaiseReminders() {
  if (pendingReminder) {
    return;
  }

  const now = Date.now();
  const lastActivity = state.lastActivityAt ? new Date(state.lastActivityAt).getTime() : 0;
  const isTodayAwake = state.lastActivityAt && state.lastActivityAt.slice(0, 10) === todayKey();

  if (isTodayAwake && lastActivity && now - lastActivity >= INACTIVITY_MS) {
    pendingReminder = {
      title: "喵，妈妈要努力搬砖给一姬买罐罐了吗！",
      body: "已经 30 分钟没有键盘或鼠标动静啦。双击一姬，我就当你回来继续上班班了。"
    };
    renderReminder();
    return;
  }

  if (state.activeTask) {
    renderReminder();
    return;
  }

  renderReminder();
}

function render() {
  renderReminder();
  renderActiveTask();
  renderSummary();
  renderTimeline();
  renderEncouragement();
  renderWeekly();
}

function renderReminder() {
  if (!pendingReminder) {
    reminderCard.hidden = true;
    reminderCard.className = "reminder-card";
    reminderTitle.textContent = "";
    reminderBody.textContent = "";
    return;
  }

  reminderCard.hidden = false;
  reminderCard.className = "reminder-card visible";
  reminderTitle.textContent = pendingReminder.title;
  reminderBody.textContent = pendingReminder.body;
}

function renderActiveTask() {
  if (!state.activeTask) {
    activeState.textContent = "待命";
    activeState.className = "status-chip idle";
    activeTaskEl.className = "active-task empty";
    activeTaskEl.innerHTML = "<p>双击一姬，弹出任务选项，选一个就自动开始计时。</p>";
    return;
  }

  const task = state.activeTask;
  const category = CATEGORY_MAP[task.category];
  activeState.textContent = task.label;
  activeState.className = `status-chip running ${category.accent}`;
  activeTaskEl.className = `active-task running ${category.accent}`;
  activeTaskEl.innerHTML = `
    <h3 class="active-task-title">${escapeHtml(task.label)}</h3>
    <div class="active-task-meta">
      <span>开始于 ${formatTime(task.startTime)}</span>
      <span>已经坚持 ${formatMinutes(diffMinutes(task.startTime, new Date().toISOString()))}</span>
    </div>
    <p>再次双击一姬就能结束，并补一句今天这段时间做成了什么。</p>
  `;
}

function renderSummary() {
  const entries = getTodayEntries();
  const totalMinutes = entries.reduce((sum, entry) => sum + diffMinutes(entry.startTime, entry.endTime), 0);
  const longest = entries.reduce((max, entry) => Math.max(max, diffMinutes(entry.startTime, entry.endTime)), 0);

  summaryCount.textContent = String(entries.length);
  summaryMinutes.textContent = String(totalMinutes);
  summaryLongest.textContent = formatMinutes(longest);
}

function renderTimeline() {
  const entries = [...getTodayEntries()].sort((a, b) => a.startTime.localeCompare(b.startTime));
  if (entries.length === 0) {
    timelineEl.innerHTML = `
      <li class="timeline-item placeholder">
        <div class="timeline-window">今天</div>
        <div>
          <h3 class="timeline-title">你的 schedule 会长在这里</h3>
          <div class="timeline-details">
            <span>每结束一段，一姬就会帮你把今天的努力挂上墙。</span>
          </div>
        </div>
      </li>
    `;
    return;
  }

  timelineEl.innerHTML = entries
    .map((entry) => {
      const category = CATEGORY_MAP[entry.category] || CATEGORIES[0];
      const minutes = diffMinutes(entry.startTime, entry.endTime);
      return `
        <li class="timeline-item ${category.accent}">
          <div class="timeline-window">
            ${formatTime(entry.startTime)} - ${formatTime(entry.endTime)}
          </div>
          <div>
            <div class="timeline-badge ${category.accent}">${category.label}</div>
            <h3 class="timeline-title">${escapeHtml(entry.outcome || `${entry.label} 完成一段`)}</h3>
            <div class="timeline-details">
              <span>${formatMinutes(minutes)}</span>
              ${entry.feeling ? `<span>${escapeHtml(entry.feeling)}</span>` : "<span>没有补充细节也没关系，这一段已经算数了。</span>"}
            </div>
          </div>
        </li>
      `;
    })
    .join("");
}

function renderEncouragement() {
  const entries = getTodayEntries();
  const totalMinutes = entries.reduce((sum, entry) => sum + diffMinutes(entry.startTime, entry.endTime), 0);
  const selected = [...ENCOURAGEMENTS].reverse().find((item) => entries.length >= item.threshold) || ENCOURAGEMENTS[0];
  encouragementEl.innerHTML = `
    <strong>${selected.message}</strong>
    <span>今天已经累计 ${formatMinutes(totalMinutes)}，每一段都不是白费力气。</span>
  `;
}

function renderWeekly() {
  const rows = getRecentDays(7)
    .map((dayKey) => {
      const entries = [...getDayEntries(dayKey)].sort((a, b) => a.startTime.localeCompare(b.startTime));
      const totalMinutes = entries.reduce((sum, entry) => sum + diffMinutes(entry.startTime, entry.endTime), 0);
      const topCategory = favoriteCategory(entries);
      return {
        dayKey,
        count: entries.length,
        totalMinutes,
        topCategory
      };
    })
    .filter((row) => row.count > 0);

  if (rows.length === 0) {
    weeklyEl.innerHTML = "<p class=\"weekly-empty\">这周还没有累积数据。等你收集完几天，一姬会帮你做周报。</p>";
    return;
  }

  const bestDay = [...rows].sort((a, b) => b.totalMinutes - a.totalMinutes)[0];
  weeklyEl.innerHTML = `
    <div class="weekly-highlight">
      <strong>本周最扎实的一天：${formatDateLabel(bestDay.dayKey)}</strong>
      <span>${formatMinutes(bestDay.totalMinutes)}，共 ${bestDay.count} 段。</span>
    </div>
    <div class="weekly-list">
      ${rows
        .map((row) => {
          const category = row.topCategory ? CATEGORY_MAP[row.topCategory] : null;
          return `
            <article class="weekly-row">
              <div>
                <h3>${formatDateLabel(row.dayKey)}</h3>
                <p>${row.count} 段任务，${formatMinutes(row.totalMinutes)}</p>
              </div>
              <div class="weekly-meta">
                <span class="mini-pill ${category ? category.accent : "neutral"}">${category ? category.label : "均匀分布"}</span>
              </div>
            </article>
          `;
        })
        .join("")}
    </div>
  `;
}

function favoriteCategory(entries) {
  if (!entries.length) {
    return null;
  }

  const totals = {};
  entries.forEach((entry) => {
    totals[entry.category] = (totals[entry.category] || 0) + diffMinutes(entry.startTime, entry.endTime);
  });

  return Object.entries(totals).sort((a, b) => b[1] - a[1])[0][0];
}

function getRecentDays(count) {
  return Array.from({ length: count }, (_, index) => {
    const day = new Date();
    day.setDate(day.getDate() - index);
    return day.toISOString().slice(0, 10);
  }).reverse();
}

function diffMinutes(startIso, endIso) {
  const diffMs = new Date(endIso).getTime() - new Date(startIso).getTime();
  return Math.max(1, Math.round(diffMs / 60000));
}

function formatTime(iso) {
  return new Date(iso).toLocaleTimeString([], {
    hour: "numeric",
    minute: "2-digit"
  });
}

function formatDateLabel(dayKey) {
  const date = new Date(`${dayKey}T12:00:00`);
  return date.toLocaleDateString([], {
    month: "short",
    day: "numeric",
    weekday: "short"
  });
}

function formatMinutes(minutes) {
  if (minutes >= 60) {
    const hours = Math.floor(minutes / 60);
    const remainder = minutes % 60;
    return remainder ? `${hours}h ${remainder}m` : `${hours}h`;
  }
  return `${minutes}m`;
}

function escapeHtml(value) {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;")
    .replaceAll("'", "&#39;");
}
