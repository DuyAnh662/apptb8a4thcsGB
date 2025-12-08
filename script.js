/* * LIQUID GLASS OS 4.1 - FIX DATES & DUTY
 * Fix: Logic so sánh ngày sự kiện (Tết), Hiển thị lịch trực
 */

const SUBJECT_PRIORITY = ["toán", "văn", "anh", "khtn", "lý", "hóa", "sinh", "sử", "địa", "gdcd", "tin", "công nghệ", "thể dục", "nghệ thuật", "hđtn", "shl"];

// --- MAIN STATE ---
const state = {
    tkb: [], btvn: [], updates: [],
    theme: localStorage.getItem('theme') || 'blue',
    isDark: localStorage.getItem('dark') === 'true',
    isLiquid: localStorage.getItem('liquid') !== 'false',
    isAutoRefresh: localStorage.getItem('autoRefresh') === 'true',
    tomorrowSubjects: [],
    displayDay: 0,

    // Mobile detection
    isTouchDevice: false,

    // New flags for event dark mode override
    isEventDarkModeActive: false,
    userDarkBeforeEvent: localStorage.getItem('dark') === 'true',

    // Event theme management
    isEventThemeActive: false,
    userThemeBeforeEvent: localStorage.getItem('theme') || 'blue'
    ,
    // Preserve liquid effect preference during events
    userLiquidBeforeEvent: localStorage.getItem('liquid') !== 'false'
};

let autoRefreshInterval = null;

const E = {
    loading: document.getElementById('loading-screen'),
    tabs: document.querySelectorAll('.tab-item'),
    panels: document.querySelectorAll('.tab-panel'),
    btvnContainer: document.getElementById('container-btvn'),
    tkbContainer: document.getElementById('container-tkb-today'),
    updatesContainer: document.getElementById('container-updates'),
    fullWeekContent: document.getElementById('content-full-week'),
    themeToggle: document.getElementById('btn-theme-toggle'),
    switchDark: document.getElementById('switch-darkmode'),
    switchLiquid: document.getElementById('switch-liquid'),
    switchAutoRefresh: document.getElementById('switch-autorefresh'),
    dockRefreshBtn: document.querySelector('[data-action="refresh"]'),
    dockContainer: document.querySelector('.glass-dock'),
    skyCanvas: document.getElementById('sky'),
    fireworksContainer: document.getElementById('fireworks-container')
};

// --- APP INIT ---
async function initApp() {
    // Detect touch/mobile device
    state.isTouchDevice = () => {
        return (('ontouchstart' in window) ||
            (navigator.maxTouchPoints > 0) ||
            (navigator.msMaxTouchPoints > 0));
    };

    // Add class to body if touch device to disable hover effects
    if (state.isTouchDevice) {
        document.body.classList.add('touch-device');
    }

    setupSettingsHandlers();

    // Luôn chạy cả tính năng sự kiện + stable features
    applyTheme();
    setupEventListeners();
    setupLiquidEffects();
    DevFeatures.init();
    try { await fetchData(true); } catch (err) { console.error(err); }

    // Load notification history
    setTimeout(() => renderNotificationHistory(), 1000);

    // Hide loading
    setTimeout(() => {
        if (E.loading) {
            E.loading.style.opacity = '0';
            setTimeout(() => E.loading.remove(), 300);
        }
    }, 500);

    // Notification setup: register service worker, request permission and subscribe to Supabase changes
    try { await setupNotifications(); } catch (e) { console.warn('Notification setup failed', e); }
}

// --- SHARED DATA FETCHING ---
async function fetchData(isSilent = false) {
    const [resBtvn, resTkb, resLog] = await Promise.all([
        window.supabase.from('btvn').select('*'),
        window.supabase.from('tkb').select('*').order('tiet', { ascending: true }),
        window.supabase.from('changelog').select('*').order('created_at', { ascending: false })
    ]);

    state.btvn = resBtvn.data || [];
    state.tkb = resTkb.data || [];
    state.updates = resLog.data || [];

    // Luôn chạy render qua DevFeatures (bao gồm tính năng sự kiện)
    DevFeatures.processData({ btvn: state.btvn, tkb: state.tkb, changelog: state.updates });
    if (!isSilent && !state.isAutoRefresh) showToast("Đã cập nhật dữ liệu");
}

// --- SETTINGS HANDLERS ---
function setupSettingsHandlers() {
    // Dev Mode bị xóa - các tính năng sự kiện luôn hoạt động
}

/* ==========================================================================
   STABLE FEATURES (Liquid Glass OS Core)
   ========================================================================== */

// --- TRONG script.js ---

function setupEventListeners() {
    // ... (Giữ nguyên phần xử lý Tab indicator cũ ở đây) ...
    const indicator = document.querySelector('.tab-indicator');
    const updateInd = (el) => { if (!el || !indicator) return; indicator.style.width = el.offsetWidth + 'px'; indicator.style.transform = `translateX(${el.offsetLeft}px)`; };
    E.tabs.forEach(t => t.addEventListener('click', (e) => {
        E.tabs.forEach(x => x.classList.remove('active'));
        E.panels.forEach(x => x.classList.remove('active'));
        e.currentTarget.classList.add('active');
        updateInd(e.currentTarget);
        document.getElementById(`panel-${t.dataset.tab}`).classList.add('active');
    }));
    setTimeout(() => updateInd(document.querySelector('.tab-item.active')), 200);
    window.addEventListener('resize', () => updateInd(document.querySelector('.tab-item.active')));
    // ... (Kết thúc phần Tab) ...

    const saveAndApply = () => {
        localStorage.setItem('theme', state.theme);
        localStorage.setItem('dark', state.isDark);
        localStorage.setItem('liquid', state.isLiquid);
        localStorage.setItem('autoRefresh', state.isAutoRefresh);
        applyTheme();
    };

    // Xử lý nút Dark Mode (guard nếu phần tử không tồn tại)
    if (E.themeToggle) {
        const toggleTheme = (evt) => {
            if (evt && evt.type === 'touchstart') evt.preventDefault();
            state.isDark = !state.isDark;
            saveAndApply();
            // reflect aria-pressed for screen readers
            try { E.themeToggle.setAttribute('aria-pressed', !!state.isDark); } catch (e) { }
        };
        E.themeToggle.addEventListener('click', toggleTheme);
        E.themeToggle.addEventListener('touchstart', toggleTheme, { passive: false });
        E.themeToggle.setAttribute('role', 'button');
    }

    // Handle device orientation / landscape class
    function handleOrientation() {
        const isLandscape = (window.matchMedia && window.matchMedia('(orientation: landscape)').matches) || (window.innerWidth > window.innerHeight);
        document.body.classList.toggle('landscape', !!isLandscape);
    }
    handleOrientation();
    window.addEventListener('orientationchange', handleOrientation);
    window.addEventListener('resize', handleOrientation);

    // Toggle App-mode (expand from window to app) on header tap
    const headerEl = document.querySelector('.window-header');
    const appEl = document.querySelector('.app-container');
    if (headerEl && appEl) {
        headerEl.addEventListener('click', () => {
            appEl.classList.toggle('app-mode');
            document.body.classList.toggle('app-mode-active', appEl.classList.contains('app-mode'));
        });
    }

    if (E.switchDark) E.switchDark.addEventListener('change', (e) => {
        state.isDark = e.target.checked;
        saveAndApply();
    });

    // --- CẬP NHẬT PHẦN CHỌN MÀU (COLOR PICKER) ---
    document.querySelectorAll('.color-dot').forEach(dot => {
        dot.addEventListener('click', (event) => {
            // Kiểm tra nếu event đang active thì khóa thay đổi màu
            if (state.isEventThemeActive) {
                showToast(`⚠️ Không thể thay đổi màu khi sự kiện đang diễn ra!`);
                return;
            }

            const selectedColor = event.currentTarget.dataset.color;

            // 1. Cập nhật state
            state.theme = selectedColor;

            // 2. Lưu và áp dụng
            saveAndApply();
            showToast(`Đã đổi chủ đề sang: ${capitalize(selectedColor)}`);
        });
    });

    // Các listener khác giữ nguyên...
    if (E.switchLiquid) E.switchLiquid.addEventListener('change', (e) => {
        // Nếu event đang chạy -> không cho tắt/bật hiệu ứng
        if (state.isEventThemeActive) {
            showToast("⚠️ Hiệu ứng được khóa trong thời gian diễn ra sự kiện");
            // đảm bảo checkbox luôn true
            e.target.checked = true;
            return;
        }
        state.isLiquid = e.target.checked;
        saveAndApply();
        showToast("Đã lưu cài đặt hiệu ứng");
    });
    if (E.switchAutoRefresh) E.switchAutoRefresh.addEventListener('change', (e) => { state.isAutoRefresh = e.target.checked; saveAndApply(); });

    document.querySelectorAll('[data-action="settings"]').forEach(b => b.addEventListener('click', () => document.getElementById('modal-settings').classList.add('open')));
    document.getElementById('btn-full-week').addEventListener('click', () => document.getElementById('modal-tkb').classList.add('open'));

    // Xử lý đóng modal
    document.querySelectorAll('.btn-close, .modal-overlay').forEach(e => e.addEventListener('click', (evt) => {
        if (evt.target === e || e.classList.contains('btn-close')) {
            document.querySelectorAll('.modal-overlay').forEach(m => m.classList.remove('open'));
        }
    }));

    E.dockRefreshBtn.addEventListener('click', () => {
        const icon = E.dockRefreshBtn.querySelector('i'); icon.classList.add('fa-spin');
        fetchData().then(() => setTimeout(() => icon.classList.remove('fa-spin'), 500));
    });
}

// Hàm hỗ trợ viết hoa chữ cái đầu
function capitalize(s) { return s && s[0].toUpperCase() + s.slice(1); }

function applyTheme() {
    // 1. Xử lý Dark Mode & Liquid Mode
    document.body.classList.toggle('dark', state.isDark);
    document.body.classList.toggle('no-liquid', !state.isLiquid);

    // 2. Xử lý Màu chủ đạo (Xóa cũ -> Thêm mới)
    const themeClasses = ['theme-blue', 'theme-pink', 'theme-green', 'theme-purple'];
    document.body.classList.remove(...themeClasses);
    document.body.classList.add(`theme-${state.theme}`);

    // 3. Cập nhật trạng thái các nút gạt trong Cài đặt (để đồng bộ khi load lại trang)
    if (E.switchDark) E.switchDark.checked = state.isDark;
    if (E.switchLiquid) {
        E.switchLiquid.checked = state.isLiquid;
        E.switchLiquid.disabled = state.isEventThemeActive === true;
    }
    if (E.switchAutoRefresh) E.switchAutoRefresh.checked = state.isAutoRefresh;

    // 4. Update active dot (chấm màu) in Settings + khóa khi event active
    document.querySelectorAll('.color-dot').forEach(d => {
        d.classList.toggle('active', d.dataset.color === state.theme);
        // Khóa/mở khóa color picker nếu event đang chạy
        d.style.opacity = state.isEventThemeActive ? '0.5' : '1';
        d.style.pointerEvents = state.isEventThemeActive ? 'none' : 'auto';
        d.style.cursor = state.isEventThemeActive ? 'not-allowed' : 'pointer';
    });

    // --- BỔ SUNG QUAN TRỌNG: XỬ LÝ DOCK ---
    // Nếu Auto Refresh đang BẬT -> Thêm class 'single-mode' để ẩn nút Refresh
    if (state.isAutoRefresh) {
        E.dockContainer.classList.add('single-mode');
    } else {
        E.dockContainer.classList.remove('single-mode');
    }

    // Cập nhật icon trên nút theme toggle để phản ánh state hiện tại
    if (E.themeToggle) {
        try {
            E.themeToggle.innerHTML = state.isDark ? '<i class="fas fa-sun"></i>' : '<i class="fas fa-moon"></i>';
        } catch (err) {
            // Không phá vỡ luồng nếu có lỗi bất ngờ
            console.warn('Không thể cập nhật icon nút theme:', err);
        }
    }
}

function setupLiquidEffects() {
    // 3D tilt effect disabled by user request
    // Cards no longer follow mouse movement
}


function calculateTomorrowSubjects() {
    const now = new Date();
    let day = now.getDay();
    if (now.getHours() >= 16) day++;
    if (day >= 6 || day === 0) day = 1;
    state.displayDay = day;
    const list = state.tkb.filter(i => Number(i.day) === day);
    state.tomorrowSubjects = list.map(i => (i.subject || '').toLowerCase());
}

// --- RENDERERS ---
const getIcon = (n) => {
    n = (n || '').toLowerCase();
    if (n.includes('toán')) return '<i class="fas fa-calculator"></i>';
    if (n.includes('văn')) return '<i class="fas fa-feather-alt"></i>';
    if (n.includes('anh')) return '<i class="fas fa-language"></i>';
    if (n.includes('khtn') || n.includes('lý') || n.includes('hóa') || n.includes('sinh')) return '<i class="fas fa-flask"></i>';
    if (n.includes('sử') || n.includes('địa') || n.includes('khxh')) return '<i class="fas fa-globe"></i>';
    if (n.includes('tin')) return '<i class="fas fa-laptop-code"></i>';
    return '<i class="fas fa-book"></i>';
};

const renderTimelineRow = (item) => `
    <div class="tkb-row">
        <div class="tkb-time">T${item.tiet}</div>
        <div class="tkb-line"></div>
        <div class="tkb-info"><div class="tkb-icon">${getIcon(item.subject)}</div><div class="tkb-name">${item.subject}</div></div>
    </div>`;

// --- HELPER: Lấy dữ liệu trực nhật an toàn ---
function getDutyText(list) {
    // Tìm trong danh sách tiết học xem có dòng nào chứa thông tin trực nhật không
    // Ưu tiên kiểm tra các trường: truc, truc_nhat, notes, duty
    const dutyItem = list.find(i => i.truc || i.truc_nhat || i.notes || i.duty);
    if (!dutyItem) return null;
    return dutyItem.truc || dutyItem.truc_nhat || dutyItem.notes || dutyItem.duty;
}

function renderBTVN() {
    E.btvnContainer.innerHTML = '';
    if (!state.btvn.length) { E.btvnContainer.innerHTML = `<div style="text-align:center; color:var(--text-sec); margin-top:20px;">Không có bài tập! 🎉</div>`; return; }
    const grouped = state.btvn.reduce((acc, item) => { const s = item.subject || 'Khác'; if (!acc[s]) acc[s] = []; acc[s].push(item); return acc; }, {});
    const isTomorrow = (name) => state.tomorrowSubjects.some(t => name.toLowerCase().includes(t) || t.includes(name.toLowerCase()));
    const sortedKeys = Object.keys(grouped).sort((a, b) => {
        const aNext = isTomorrow(a); const bNext = isTomorrow(b);
        if (aNext && !bNext) return -1; if (!aNext && bNext) return 1; return 0;
    });
    sortedKeys.forEach(subj => {
        const card = document.createElement('div');
        card.className = 'subject-card';
        if (isTomorrow(subj)) {
            card.classList.add('highlight-tomorrow');
            const badge = document.createElement('div'); badge.className = 'tomorrow-badge'; badge.textContent = 'Sắp học'; card.appendChild(badge);
        }
        card.innerHTML += `<div class="subject-title">${getIcon(subj)} ${subj}</div><ul>${grouped[subj].map(i => `<li class="btvn-item">${i.content || i.note}</li>`).join('')}</ul>`;
        E.btvnContainer.appendChild(card);
    });
}

function renderTKB() {
    const day = state.displayDay || 1;
    const list = state.tkb.filter(i => Number(i.day) === day);

    // SỬA: Lấy thông tin trực nhật
    const dutyText = getDutyText(list);

    let html = '';
    const dayName = ["", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"][day];
    html += `<div style="font-size:18px; font-weight:800; margin-bottom:10px;">${dayName}</div>`;

    // HIỂN THỊ TRỰC NHẬT
    if (dutyText && dutyText !== "Null" && dutyText !== "Không trực") {
        html += `<div class="duty-badge"><i class="fas fa-broom"></i> ${dutyText}</div>`;
    }

    if (!list.length) { E.tkbContainer.innerHTML = html + `<div class="card" style="text-align:center;color:var(--text-sec);padding:30px;">Không có lịch học</div>`; renderFullWeek(); return; }

    const isAfternoon = (i) => (i.buoi || '').toLowerCase().includes('chiều') || i.tiet > 5;
    const morning = list.filter(i => !isAfternoon(i)).sort((a, b) => a.tiet - b.tiet);
    const afternoon = list.filter(i => isAfternoon(i)).sort((a, b) => a.tiet - b.tiet);

    if (morning.length) html += `<div style="color:var(--primary);font-weight:bold;margin:10px 0 5px 0;">Buổi Sáng <i class="fas fa-sun"></i></div><div class="card" style="padding:5px 15px;">${morning.map(renderTimelineRow).join('')}</div>`;
    if (afternoon.length) html += `<div style="color:var(--primary);font-weight:bold;margin:10px 0 5px 0;">Buổi Chiều <i class="fas fa-cloud-moon"></i></div><div class="card" style="padding:5px 15px;">${afternoon.map(renderTimelineRow).join('')}</div>`;

    E.tkbContainer.innerHTML = html;

    // Cập nhật popup Full Week
    renderFullWeek();
}

// --- HÀM FULL WEEK (Đã cập nhật theo yêu cầu của bạn) ---
function renderFullWeek() {
    const days = ["", "Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7"];
    let html = '';
    for (let d = 1; d <= 6; d++) {
        const list = state.tkb.filter(i => Number(i.day) === d);
        if (!list.length) continue;

        // SỬA: Lấy thông tin trực nhật cho từng ngày
        const dutyText = getDutyText(list);

        const isAfternoon = (i) => (i.buoi || '').toLowerCase().includes('chiều') || i.tiet > 5;
        const morning = list.filter(i => !isAfternoon(i)).sort((a, b) => a.tiet - b.tiet);
        const afternoon = list.filter(i => isAfternoon(i)).sort((a, b) => a.tiet - b.tiet);

        html += `
        <div class="week-day-card">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                <div class="day-header-badge">${days[d]}</div>
                ${(dutyText && dutyText !== "Null") ? `<div style="font-size:12px; font-weight:bold; color:var(--text-sec);"><i class="fas fa-broom"></i> ${dutyText}</div>` : ''}
            </div>
            ${morning.length ? `<div style="font-size:12px; text-transform:uppercase; color:var(--primary); font-weight:700; margin:5px 0; border-bottom:1px solid rgba(0,0,0,0.05);">Sáng</div>${morning.map(renderTimelineRow).join('')}` : ''}
            ${afternoon.length ? `<div style="font-size:12px; text-transform:uppercase; color:var(--primary); font-weight:700; margin:15px 0 5px 0; border-bottom:1px solid rgba(0,0,0,0.05);">Chiều</div>${afternoon.map(renderTimelineRow).join('')}` : ''}
        </div>`;
    }
    E.fullWeekContent.innerHTML = html;
}

function renderUpdates() {
    E.updatesContainer.innerHTML = state.updates.length
        ? state.updates.map(u => `<div class="card"><div style="font-weight:bold;color:var(--primary);margin-bottom:5px;"><i class="fas fa-bullhorn"></i> Thông báo</div><div style="white-space: pre-wrap;">${u.content || u.text}</div></div>`).join('')
        : '<div style="text-align:center;color:var(--text-sec);">Không có tin tức</div>';
}

async function renderNotificationHistory() {
    if (!window.supabase) return;
    const container = document.getElementById('container-notifications');
    if (!container) return;

    try {
        const { data } = await window.supabase
            .from('notification')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(50);

        if (!data || data.length === 0) {
            container.innerHTML = '<div style="text-align:center;color:var(--text-sec);">Chưa có thông báo nào</div>';
            return;
        }

        const html = data.map(n => {
            const time = new Date(n.created_at).toLocaleString('vi-VN');
            const icon = n.type === 'daily' ? '📚' : (n.type === 'event' ? '🎉' : (n.type === 'free' ? '📢' : '📬'));
            return `
                <div class="card" style="margin-bottom: 10px; padding: 12px; border-left: 3px solid var(--primary);">
                    <div style="font-weight: bold; margin-bottom: 5px;">${icon} ${n.title}</div>
                    <div style="font-size: 13px; margin-bottom: 8px; color: var(--text-sec);">${n.message}</div>
                    <div style="font-size: 11px; color: var(--text-sec); opacity: 0.7;">${time}</div>
                </div>
            `;
        }).join('');

        container.innerHTML = html;
    } catch (e) {
        console.warn('Render notification history failed', e);
        container.innerHTML = '<div style="color:red;">Lỗi tải thông báo</div>';
    }
}

function showToast(msg) {
    const d = document.createElement('div');
    d.style.cssText = "position:fixed;top:20px;left:50%;transform:translateX(-50%);background:rgba(0,0,0,0.8);color:white;padding:10px 20px;border-radius:20px;z-index:9999;backdrop-filter:blur(10px);font-size:13px;font-weight:500;";
    d.innerText = msg;
    document.body.appendChild(d);
    setTimeout(() => { d.style.opacity = '0'; setTimeout(() => d.remove(), 300); }, 2000);
}
/* ==========================================================================
   DEV FEATURES (BETA MODULE)
   ========================================================================== */

const DevFeatures = {
    // SỬA: Cập nhật cấu trúc ngày để test dễ hơn
    // Bạn có thể sửa ngày ở đây để test.
    specialEvents: [
        //Sự kiện Tết (Ví dụ test ngày hiện tại)
        { name: "Tết", startDate: { m: 2, d: 16 }, endDate: { m: 2, d: 24 }, theme: "tet", fireworks: true, isDarkMode: true, popup: { title: "Chúc Mừng Năm Mới!", content: "An khang thịnh vượng - Vạn sự như ý!" } },

        //Sự kiện Halloween (Tháng 10)
        { name: "Halloween", startDate: { m: 10, d: 30 }, endDate: { m: 11, d: 1 }, theme: "halloween", fireworks: false, isDarkMode: true, popup: { title: "Happy Halloween!", content: "Trick or Treat! Cẩn thận ma quỷ...! >:)" } },

        //Sự kiện Giáng Sinh (Tháng 12) ---
        { name: "Noel", startDate: { m: 12, d: 24 }, endDate: { m: 12, d: 26 }, theme: "christmas", fireworks: true, isDarkMode: true, popup: { title: "Merry Christmas!", content: "Chúc bạn một mùa Giáng sinh an lành và ấm áp! 🎄❄️" } }
    ],
    currentEvent: null,

    init() {
        this.checkSpecialEvents();
        this.setupDevListeners();
        if (!this.currentEvent || !this.currentEvent.disableMeteors) {
            this.initCanvas();
        }
        fetchData(true);
    },

    setupDevListeners() {
        applyTheme();
        setupEventListeners();
        const evClose = document.getElementById('eventPopupClose');
        if (evClose) evClose.addEventListener('click', () => document.getElementById('eventPopup').classList.remove('open'));
    },

    checkSpecialEvents() {
        const today = new Date();
        const m = today.getMonth() + 1;
        const d = today.getDate();

        // SỬA: Logic kiểm tra ngày thông minh hơn (Convert ra số để so sánh: Tháng*100 + Ngày)
        // Ví dụ: 29/1 => 129, 5/2 => 205.
        const currentVal = m * 100 + d;

        const event = this.specialEvents.find(e => {
            const startVal = e.startDate.m * 100 + e.startDate.d;
            const endVal = e.endDate.m * 100 + e.endDate.d;

            if (startVal <= endVal) {
                // Cùng năm (VD: 1/1 đến 28/2) -> 101 <= 228
                return currentVal >= startVal && currentVal <= endVal;
            } else {
                // Vắt qua năm (VD: 25/12 đến 5/1) -> 1225 > 105
                return currentVal >= startVal || currentVal <= endVal;
            }
        });

        // Clear previous event class if any
        if (this.currentEvent && document.body.classList.contains(`event-${this.currentEvent.theme}`)) {
            document.body.classList.remove(`event-${this.currentEvent.theme}`);
        }

        if (event) {
            this.currentEvent = event;

            // Lưu theme hiện tại trước khi thay đổi
            if (!state.isEventThemeActive) {
                state.userThemeBeforeEvent = state.theme;
            }

            // BƯỚC 1: Lưu và chuyển sang blue tạm thời
            if (!('userLiquidBeforeEvent' in state)) state.userLiquidBeforeEvent = state.isLiquid;
            // Save current theme already handled above
            state.theme = 'blue';
            // Ensure liquid effects ON during event and lock the switch
            state.userLiquidBeforeEvent = state.userLiquidBeforeEvent === undefined ? state.isLiquid : state.userLiquidBeforeEvent;
            state.isLiquid = true;
            state.isEventThemeActive = true;
            if (E.switchLiquid) E.switchLiquid.disabled = true;
            applyTheme();

            // BƯỚC 2: Thêm class event (áp dụng theme event)
            document.body.classList.add(`event-${event.theme}`);
            applyTheme();

            if (event.isDarkMode) {
                if (!state.isEventDarkModeActive) {
                    // Save current user preference before overriding
                    state.userDarkBeforeEvent = state.isDark;
                }
                state.isDark = true;
                state.isEventDarkModeActive = true;

                // Disable dark mode toggle UI during event
                if (E.themeToggle) E.themeToggle.disabled = true;
                if (E.switchDark) E.switchDark.disabled = true;

                applyTheme();
            } else {
                // For events with no dark mode override, ensure toggles enabled
                state.isEventDarkModeActive = false;
                if (E.themeToggle) E.themeToggle.disabled = false;
                if (E.switchDark) E.switchDark.disabled = false;
                applyTheme();
            }

            if (event.fireworks) this.startFireworks();

            const pop = document.getElementById('eventPopup');
            if (pop) {
                document.getElementById('eventPopupTitle').innerText = event.popup.title;
                document.getElementById('eventPopupContent').innerText = event.popup.content;
                pop.classList.add('open');
            }
            this.addPatterns(event.theme);
        } else {
            // No event currently active, restore user settings if overridden
            if (state.isEventThemeActive) {
                // Restore theme
                state.theme = state.userThemeBeforeEvent;
                state.isEventThemeActive = false;
            }

            if (state.isEventDarkModeActive) {
                // Restore dark mode
                state.isDark = state.userDarkBeforeEvent;
                state.isEventDarkModeActive = false;
                if (E.themeToggle) E.themeToggle.disabled = false;
                if (E.switchDark) E.switchDark.disabled = false;
            }
            // Restore liquid setting if it was overridden by the event
            if (state.isEventThemeActive) {
                state.isLiquid = state.userLiquidBeforeEvent;
                state.isEventThemeActive = false;
                if (E.switchLiquid) E.switchLiquid.disabled = false;
            }

            applyTheme();
            this.currentEvent = null;
        }
    },

    processData(data) {
        calculateTomorrowSubjects();
        renderBTVN();
        renderTKB();
        renderUpdates();
    },

    addPatterns(theme) {
        const container = document.createElement('div');
        container.className = 'event-patterns';

        // --- SỬA ĐOẠN NÀY ---
        let icons = [];
        if (theme === 'tet') {
            icons = ['hoa-mai', 'hoa-dao'];
        } else if (theme === 'christmas') {
            icons = ['snow', 'tree']; // Sticker Tuyết & Cây thông
        } else {
            icons = ['pumpkin', 'ghost']; // Mặc định là Halloween
        }
        // --------------------

        for (let i = 0; i < 10; i++) {
            const el = document.createElement('div');
            // ... (đoạn dưới giữ nguyên) ...
            el.className = `event-pattern pattern-${icons[i % icons.length]}`;
            el.style.left = Math.random() * 100 + '%';
            el.style.animationDelay = Math.random() * 5 + 's';
            container.appendChild(el);
        }
        document.body.appendChild(container);
    },

    initCanvas() {
        const canvas = document.getElementById('sky');
        if (!canvas) return;
        const ctx = canvas.getContext('2d');
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;

        const stars = Array(200).fill().map(() => ({
            x: Math.random() * canvas.width,
            y: Math.random() * canvas.height,
            r: Math.random() * 1.5,
            opacity: Math.random()
        }));

        function draw() {
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            if (state.isDark) {
                ctx.fillStyle = "#fff";
                stars.forEach(s => {
                    ctx.globalAlpha = s.opacity;
                    ctx.beginPath(); ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2); ctx.fill();
                });
            }
            requestAnimationFrame(draw);
        }
        draw();
    },

    startFireworks() {
        const container = document.getElementById('fireworks-container');
        if (!container) return;
        setInterval(() => {
            const fw = document.createElement('div');
            fw.className = 'firework';
            fw.style.left = Math.random() * 100 + '%';
            fw.style.top = Math.random() * 50 + '%';
            fw.style.boxShadow = "0 0 10px red";
            container.appendChild(fw);
            setTimeout(() => fw.remove(), 1000);
        }, 1000);
    }
};

document.addEventListener('DOMContentLoaded', initApp);

/* ===================== NOTIFICATION HELPERS ===================== */

const VAPID_PUBLIC_KEY = "BECwSj0xQaM3JXmGNAryUhNfQim1f0-h2cEEoSqDIrBfmYQi6g1aNUsCo6i1AN4k4-4LawmTOMrpTiM4cbn0KtA";

async function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    for (let i = 0; i < rawData.length; ++i) outputArray[i] = rawData.charCodeAt(i);
    return outputArray;
}

async function subscribeUserForPush() {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
        console.warn('Push not supported');
        return;
    }

    try {
        const registration = await navigator.serviceWorker.ready;
        let subscription = await registration.pushManager.getSubscription();

        if (!subscription) {
            const vapidKey = await urlBase64ToUint8Array(VAPID_PUBLIC_KEY);
            subscription = await registration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: vapidKey,
            });
        }

        // Lưu subscription vào Supabase
        if (subscription && window.supabase) {
            const endpoint = subscription.endpoint;
            const p256dh = subscription.getKey('p256dh') ?
                btoa(String.fromCharCode.apply(null, new Uint8Array(subscription.getKey('p256dh')))) : '';
            const auth = subscription.getKey('auth') ?
                btoa(String.fromCharCode.apply(null, new Uint8Array(subscription.getKey('auth')))) : '';

            const { error } = await window.supabase.from('push_subscriptions').insert({
                endpoint,
                p256dh,
                auth,
                user_agent: navigator.userAgent,
                platform: navigator.platform,
            });

            if (!error) {
                console.log('[Push] Subscription saved to Supabase');
            } else {
                console.warn('[Push] Save subscription error:', error);
            }
        }
    } catch (err) {
        console.warn('[Push] Subscribe error:', err);
    }
}

async function setupNotifications() {
    // Register service worker
    if ('serviceWorker' in navigator) {
        try {
            const reg = await navigator.serviceWorker.register('service-worker.js');
            window.swRegistration = reg;
            console.log('SW registered', reg);
        } catch (e) {
            console.warn('SW register failed', e);
        }
    }

    // Request notification permission if not granted
    if (typeof Notification !== 'undefined' && Notification.permission === 'default') {
        try {
            const perm = await Notification.requestPermission();
            if (perm === 'granted') {
                // Subscribe for push khi được phép
                setTimeout(subscribeUserForPush, 500);
            }
        } catch (e) { console.warn('Notification request failed', e); }
    } else if (Notification.permission === 'granted') {
        // Nếu đã được phép trước đó, subscribe luôn
        setTimeout(subscribeUserForPush, 500);
    }

    // Listen to messages from service worker (notification clicks)
    if (navigator.serviceWorker && navigator.serviceWorker.addEventListener) {
        navigator.serviceWorker.addEventListener('message', (ev) => {
            if (!ev.data) return;
            if (ev.data.type === 'notification_click') {
                handleNotificationNavigation(ev.data.data);
            }
        });
    }

    // Subscribe to Supabase realtime notifications from `notification` table
    try {
        if (window.supabase && window.supabase.channel) {
            const channel = window.supabase.channel('notif_channel')
                .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'notification' }, (payload) => {
                    const n = payload.new;
                    if (!n) return;
                    const title = n.title || 'Thông báo mới';
                    const body = n.message || n.content || '';
                    const url = n.url || '/';
                    showClientNotification({ title, body, url, id: n.id });
                    // Reload notification history
                    setTimeout(() => renderNotificationHistory(), 500);
                })
                .subscribe();
            window._notifChannel = channel;
        }
    } catch (e) { console.warn('Supabase realtime setup failed', e); }
}

function handleNotificationNavigation(data) {
    // Focus app and switch to BTVN tab when requested
    try {
        if (data && data.tab === 'btvn') {
            const tab = document.querySelector('.tab-item[data-tab="btvn"]');
            if (tab) tab.click();
            // also open panel
            const panel = document.getElementById('panel-btvn');
            if (panel) {
                document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
                panel.classList.add('active');
            }
        }
    } catch (e) { console.warn(e); }
}

function showClientNotification(opts) {
    const title = opts.title || 'Thông báo';
    const body = opts.body || '';
    const url = opts.url || '/';
    const data = { url, tab: 'btvn', from: 'supabase', id: opts.id };

    // Hiện toast (thông báo nhỏ trên trang)
    showToast(`📢 ${title}: ${body}`);

    // Prefer service worker showNotification when possible
    if (window.swRegistration && window.swRegistration.showNotification) {
        try {
            window.swRegistration.showNotification(title, { body, icon: '/icons/icon-192.png', data, vibrate: [100, 50, 100] });
            return;
        } catch (e) { console.warn('sw showNotification failed', e); }
    }

    // Fallback to Notification API
    if (typeof Notification !== 'undefined' && Notification.permission === 'granted') {
        try { new Notification(title, { body, icon: '/icons/icon-192.png', data }); } catch (e) { console.warn(e); }
    }
}
/* ===================== TEST PUSH FUNCTIONS ===================== */

async function testPushNotification() {
    const btn = document.getElementById('btn-test-push');
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Đang gửi...';
    }

    try {
        const SUPABASE_URL = "https://nlmwiyoplederbthjvzz.supabase.co";
        const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sbXdpeW9wbGVkZXJidGhqdnp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4MzYxOTEsImV4cCI6MjA3ODQxMjE5MX0.fzyVeeLaSnYJyaIv63i9C7q6C-9UqtmL1HZuNYP-FJE";

        const response = await fetch(SUPABASE_URL + "/functions/v1/push_dispatcher", {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + SUPABASE_ANON_KEY,
            },
            body: JSON.stringify({
                record: {
                    title: "Test Push",
                    message: "Đây là thông báo kiểm tra từ nút Test.",
                    url: window.location.href,
                    type: "test"
                }
            })
        });

        const responseText = await response.text();
        console.log("Response status:", response.status);
        console.log("Response body:", responseText);

        if (!response.ok) {
            throw new Error("HTTP " + response.status + ": " + responseText);
        }

        const data = JSON.parse(responseText);
        console.log("Test Push Result:", data);
        showToast("Đã gửi yêu cầu test push! Hãy thoát app để kiểm tra.");
    } catch (e) {
        console.error("Test Push Failed:", e);
        showToast("Gửi thất bại: " + (e.message || e));
    } finally {
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-paper-plane"></i> Test Push (Gửi thử)';
        }
    }
}

function renderTestPushButton() {
    const container = document.getElementById('container-notifications');
    if (!container) return;

    if (document.getElementById('btn-test-push')) return;

    const btn = document.createElement('button');
    btn.id = 'btn-test-push';
    btn.className = 'btn-secondary full-width';
    btn.style.marginBottom = '10px';
    btn.style.border = '1px dashed var(--primary)';
    btn.innerHTML = '<i class="fas fa-paper-plane"></i> Test Push (Gửi thử)';
    btn.onclick = testPushNotification;

    container.parentNode.insertBefore(btn, container);
}

// Auto-render test button when DOM is ready
document.addEventListener('DOMContentLoaded', function () {
    setTimeout(renderTestPushButton, 2000);
});

/* ===================== TEST PUSH FUNCTIONS ===================== */

async function testPushNotification() {
    const btn = document.getElementById('btn-test-push');
    if (btn) {
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Đang gửi...';
    }

    try {
        const SUPABASE_URL = "https://nlmwiyoplederbthjvzz.supabase.co";
        const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5sbXdpeW9wbGVkZXJidGhqdnp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4MzYxOTEsImV4cCI6MjA3ODQxMjE5MX0.fzyVeeLaSnYJyaIv63i9C7q6C-9UqtmL1HZuNYP-FJE";

        const response = await fetch(SUPABASE_URL + "/functions/v1/push_dispatcher", {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + SUPABASE_ANON_KEY,
            },
            body: JSON.stringify({
                record: {
                    title: "Test Push",
                    message: "Đây là thông báo kiểm tra từ nút Test.",
                    url: window.location.href,
                    type: "test"
                }
            })
        });

        const responseText = await response.text();
        console.log("Response status:", response.status);
        console.log("Response body:", responseText);

        if (!response.ok) {
            throw new Error("HTTP " + response.status + ": " + responseText);
        }

        const data = JSON.parse(responseText);
        console.log("Test Push Result:", data);
        showToast("Đã gửi yêu cầu test push!");
    } catch (e) {
        console.error("Test Push Failed:", e);
        showToast("Gửi thất bại: " + (e.message || e));
    } finally {
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-paper-plane"></i> Test Push (Gửi thử)';
        }
    }
}

function renderTestPushButton() {
    const container = document.getElementById('container-notifications');
    if (!container) return;
    if (document.getElementById('btn-test-push')) return;

    const btn = document.createElement('button');
    btn.id = 'btn-test-push';
    btn.className = 'btn-secondary full-width';
    btn.style.marginBottom = '10px';
    btn.style.border = '1px dashed var(--primary)';
    btn.innerHTML = '<i class="fas fa-paper-plane"></i> Test Push (Gửi thử)';
    btn.onclick = testPushNotification;
    container.parentNode.insertBefore(btn, container);
}

document.addEventListener('DOMContentLoaded', function () {
    setTimeout(renderTestPushButton, 2000);
});
