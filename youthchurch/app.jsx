// app.jsx — Church metaverse app: state, HUD, room portals, bottom nav, worship room
// Depends on: scene.jsx, avatars.jsx, ios-frame.jsx, tweaks-panel.jsx (all on window)

const { useState, useEffect, useRef, useCallback } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "lightColor": "#ffb24d",
  "glassPalette": ["#7c5cff", "#3bd6c6", "#ff7eb6"],
  "darkness": 0.42,
  "godrays": true,
  "avatarStyle": "blob",
  "spaceName": "청년부 라운지"
}/*EDITMODE-END*/;

const USERS = [
  { id: 1, name: "지수", role: "찬양팀 · 건반", status: "오늘 콘티 미쳤다 🔥", color: "#7c5cff", color2: "#c5b6ff", x: 30, y: 25, scale: 0.78, live: false },
  { id: 2, name: "도윤", role: "청년부 3년차", status: "예배 5분 전 입장 완료", color: "#3bd6c6", color2: "#bdfff4", x: 64, y: 27, scale: 0.74, live: false },
  { id: 3, name: "서연", role: "새가족", status: "오늘 처음 왔어요 🙏", color: "#ff7eb6", color2: "#ffd2e7", x: 47, y: 14, scale: 1.0, live: false },
  { id: 4, name: "민재", role: "리더 · 1셀", status: "셀모임 8시 라운지에서!", color: "#ffa14d", color2: "#ffe0b8", x: 17, y: 13, scale: 1.04, live: false },
  { id: 5, name: "하은", role: "미디어팀", status: "오늘 라이브 송출 담당 🎥", color: "#5b9dff", color2: "#cfe2ff", x: 80, y: 16, scale: 0.96, live: true },
  { id: 6, name: "예준", role: "청년부 2년차", status: "큐티 나눔 구해요", color: "#9d8cff", color2: "#ddd5ff", x: 88, y: 31, scale: 0.66, live: false },
  { id: 7, name: "수아", role: "찬양팀 · 보컬", status: "사운드체크 중...", color: "#ff9bb0", color2: "#ffe2e9", x: 8, y: 30, scale: 0.68, live: false },
];

let _rid = 0;

function TopHUD({ spaceName, count, onProfile }) {
  return (
    <div className="hud-top">
      <div className="hud-pill glass">
        <span className="live-dot" />
        <span className="hud-space">{spaceName}</span>
        <span className="hud-sep" />
        <span className="hud-count">접속 <b>{count}</b></span>
      </div>
      <button className="hud-icon glass" onClick={onProfile} aria-label="프로필">
        <span className="hud-me" />
      </button>
    </div>
  );
}

function RoomPortals({ onEnter }) {
  const rooms = [
    { id: "worship", label: "주일 청년예배", sub: "LIVE · 128명", x: 50, y: 41, hue: "#ffb24d", live: true },
    { id: "prayer", label: "기도의 골방", sub: "조용히 머무는 곳", x: 20, y: 37, hue: "#7c5cff", live: false },
    { id: "lounge", label: "소그룹 라운지", sub: "셀모임 · 12개 방", x: 79, y: 38, hue: "#3bd6c6", live: false },
  ];
  return (
    <div className="portal-layer">
      {rooms.map((r) => (
        <button
          key={r.id}
          className={`portal ${r.live ? "portal-live" : ""}`}
          style={{ left: `${r.x}%`, bottom: `${r.y}%`, "--ph": r.hue }}
          onClick={() => onEnter(r.id)}
        >
          <span className="portal-arch" />
          <span className="portal-light" />
          <span className="portal-info">
            <span className="portal-label">
              {r.live && <span className="portal-live-dot" />}
              {r.label}
            </span>
            <span className="portal-sub">{r.sub}</span>
          </span>
        </button>
      ))}
    </div>
  );
}

const NAV = [
  { id: "hall", label: "홀", icon: "M3 11l9-7 9 7M5 9.5V20h14V9.5" },
  { id: "worship", label: "예배", icon: "M12 3v18M7 8h10M9 21h6" },
  { id: "lounge", label: "소그룹", icon: "M7 11a3 3 0 100-6 3 3 0 000 6zM17 11a3 3 0 100-6 3 3 0 000 6zM2 20c0-3 2.5-4.5 5-4.5M22 20c0-3-2.5-4.5-5-4.5M12 20c0-3 2-4.5 0-4.5" },
  { id: "chat", label: "채팅", icon: "M4 5h16v11H9l-4 4V16H4z" },
  { id: "me", label: "나", icon: "M12 12a4 4 0 100-8 4 4 0 000 8zM5 20c0-3.5 3-6 7-6s7 2.5 7 6" },
];

function BottomNav({ active, onNav }) {
  return (
    <div className="bottom-nav glass">
      {NAV.map((n) => (
        <button
          key={n.id}
          className={`nav-item ${active === n.id ? "is-active" : ""}`}
          onClick={() => onNav(n.id)}
        >
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
            <path d={n.icon} stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          <span>{n.label}</span>
        </button>
      ))}
    </div>
  );
}

function Toast({ msg }) {
  if (!msg) return null;
  return <div className="toast glass">{msg}</div>;
}

// ---- Worship room ----
function WorshipRoom({ onBack, reactions, onReact }) {
  const lines = ["주 은혜임을 나 알아", "이 모든 순간이 선물인 걸", "내 삶의 이유 되신 주"];
  const [idx, setIdx] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setIdx((i) => (i + 1) % lines.length), 3200);
    return () => clearInterval(t);
  }, []);
  const reactBar = ["🙏", "❤️", "🔥", "✨", "🕊️"];
  return (
    <div className="screen worship-screen">
      <WorshipScene>
        <ReactionBurst items={reactions} />
      </WorshipScene>
      <div className="worship-top">
        <button className="back-btn glass" onClick={onBack} aria-label="뒤로">‹</button>
        <div className="worship-title glass">
          <span className="live-tag">LIVE</span>
          주일 청년예배
        </div>
        <div className="viewers glass">👁 128</div>
      </div>
      <div className="lyrics">
        <div className="lyric-now" key={idx}>{lines[idx]}</div>
        <div className="lyric-next">{lines[(idx + 1) % lines.length]}</div>
      </div>
      <div className="worship-react">
        {reactBar.map((e) => (
          <button key={e} className="react-btn" onClick={() => onReact(e)}>{e}</button>
        ))}
      </div>
    </div>
  );
}

// ---- simple overlay panel for chat / me ----
function PanelOverlay({ kind, onClose, users }) {
  if (!kind) return null;
  const chat = [
    { u: "민재", c: "오늘 셀모임 8시 라운지에서 봬요!", color: "#ffa14d" },
    { u: "서연", c: "처음이라 떨리네요 잘 부탁드려요 🙏", color: "#ff7eb6" },
    { u: "지수", c: "찬양팀 사운드체크 들어갑니다", color: "#7c5cff" },
    { u: "하은", c: "라이브 송출 곧 시작할게요 🎥", color: "#5b9dff" },
  ];
  return (
    <div className="panel-overlay" onClick={onClose}>
      <div className="panel glass" onClick={(e) => e.stopPropagation()}>
        <div className="panel-grab" />
        {kind === "chat" ? (
          <>
            <div className="panel-title">청년부 라운지 채팅</div>
            <div className="chat-list">
              {chat.map((m, i) => (
                <div className="chat-row" key={i}>
                  <span className="chat-ava" style={{ background: m.color }} />
                  <div>
                    <div className="chat-u">{m.u}</div>
                    <div className="chat-c">{m.c}</div>
                  </div>
                </div>
              ))}
            </div>
            <div className="chat-input glass">메시지 보내기…<span className="send">➤</span></div>
          </>
        ) : (
          <>
            <div className="me-hero">
              <span className="me-ava" />
              <div className="me-name">은혜 <span className="me-tag">청년부 · 2셀</span></div>
              <div className="me-sub">“오늘도 주님 안에서 😊”</div>
            </div>
            <div className="me-stats">
              <div><b>34</b><span>출석</span></div>
              <div><b>12</b><span>큐티</span></div>
              <div><b>5</b><span>섬김</span></div>
            </div>
            <div className="me-rows">
              <div className="me-row">🎨 아바타 꾸미기 <span>›</span></div>
              <div className="me-row">🔔 알림 설정 <span>›</span></div>
              <div className="me-row">🙏 나의 기도제목 <span>›</span></div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [view, setView] = useState("hall");        // hall | worship | lounge
  const [overlay, setOverlay] = useState(null);     // chat | me | null
  const [selected, setSelected] = useState(null);
  const [reactions, setReactions] = useState([]);
  const [self, setSelf] = useState({ x: 50, y: 8 });
  const [toast, setToast] = useState("");
  const toastT = useRef(null);

  const showToast = useCallback((m) => {
    setToast(m);
    clearTimeout(toastT.current);
    toastT.current = setTimeout(() => setToast(""), 2200);
  }, []);

  const addReaction = useCallback((emoji, x, y) => {
    const id = ++_rid;
    const r = { id, emoji, x: x ?? 30 + Math.random() * 40, y: y ?? 26, drift: (Math.random() - 0.5) * 70 };
    setReactions((rs) => [...rs, r]);
    setTimeout(() => setReactions((rs) => rs.filter((x) => x.id !== id)), 2600);
  }, []);

  const onGreet = (user, emoji = "👋") => {
    addReaction(emoji, user.x, user.y + 14);
    setSelected(null);
    showToast(`${user.name}님에게 ${emoji} 인사를 보냈어요`);
  };

  const moveSelf = (e) => {
    if (selected) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const px = ((e.clientX - rect.left) / rect.width) * 100;
    const py = ((rect.bottom - e.clientY) / rect.height) * 100;
    const x = Math.max(8, Math.min(92, px));
    const y = Math.max(5, Math.min(34, py));
    setSelf({ x, y });
  };

  const nav = (id) => {
    if (id === "chat" || id === "me") { setOverlay(id); return; }
    setOverlay(null);
    setView(id);
  };

  const enterRoom = (id) => {
    if (id === "worship") setView("worship");
    else if (id === "lounge") setView("lounge");
    else showToast("기도의 골방에 입장했어요 🙏");
  };

  // scene styles from tweaks
  const sceneVars = {
    "--light": t.lightColor,
    "--glass1": t.glassPalette[0],
    "--glass2": t.glassPalette[1],
    "--glass3": t.glassPalette[2],
    "--dark": t.darkness,
  };

  const hallUsers = USERS;
  const loungeUsers = USERS.slice(0, 5).map((u, i) => ({ ...u, x: 18 + i * 16, y: 16 + (i % 2) * 8, scale: 0.8 + (i % 2) * 0.15 }));

  return (
    <div className="app-root" style={sceneVars}>
      <IOSDevice dark>
        <div className="stage-wrap">
          {view === "worship" ? (
            <WorshipRoom
              onBack={() => setView("hall")}
              reactions={reactions}
              onReact={(e) => addReaction(e, 30 + Math.random() * 40, 30)}
            />
          ) : (
            <div className="screen hall-screen">
              <ChurchScene godrays={t.godrays}>
                <div className="floor-tap" onClick={moveSelf} />
                <AvatarLayer
                  users={view === "lounge" ? loungeUsers : hallUsers}
                  avatarStyle={t.avatarStyle}
                  onTapUser={setSelected}
                  selectedId={selected?.id}
                />
                <SelfAvatar pos={self} style={t.avatarStyle} />
                {view === "hall" && <RoomPortals onEnter={enterRoom} />}
                <ReactionBurst items={reactions} />
              </ChurchScene>

              <TopHUD
                spaceName={view === "lounge" ? "소그룹 라운지" : t.spaceName}
                count={view === "lounge" ? 18 : 42}
                onProfile={() => setOverlay("me")}
              />

              {view === "hall" && (
                <div className="hall-hint">바닥을 탭하면 이동해요 · 아바타를 탭해 인사하기</div>
              )}
              {view === "lounge" && (
                <div className="lounge-banner glass">
                  <b>2셀 · 수요 나눔</b><span>지금 5명이 모여있어요</span>
                </div>
              )}
            </div>
          )}

          <ProfileCard user={selected} onClose={() => setSelected(null)} onGreet={onGreet} />
          <PanelOverlay kind={overlay} onClose={() => setOverlay(null)} users={USERS} />
          <Toast msg={toast} />

          {view !== "worship" && <BottomNav active={overlay || view} onNav={nav} />}
        </div>
      </IOSDevice>

      <TweaksPanel>
        <TweakSection label="조명 & 분위기" />
        <TweakColor label="조명 색" value={t.lightColor}
          options={["#ffb24d", "#7c5cff", "#3bd6c6", "#ff7eb6", "#ffffff"]}
          onChange={(v) => setTweak("lightColor", v)} />
        <TweakSlider label="어둡기" value={t.darkness} min={0.1} max={0.7} step={0.02}
          onChange={(v) => setTweak("darkness", v)} />
        <TweakToggle label="빛기둥(godray)" value={t.godrays}
          onChange={(v) => setTweak("godrays", v)} />
        <TweakSection label="스테인드글라스" />
        <TweakColor label="유리 색감" value={t.glassPalette}
          options={[["#7c5cff", "#3bd6c6", "#ff7eb6"], ["#ff8a4d", "#ffd24d", "#ff5e7e"], ["#4d7bff", "#3bd6c6", "#8c5cff"]]}
          onChange={(v) => setTweak("glassPalette", v)} />
        <TweakSection label="아바타" />
        <TweakRadio label="스타일" value={t.avatarStyle}
          options={["blob", "figure", "orb"]}
          onChange={(v) => setTweak("avatarStyle", v)} />
        <TweakSection label="공간" />
        <TweakText label="공간 이름" value={t.spaceName}
          onChange={(v) => setTweak("spaceName", v)} />
      </TweaksPanel>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
