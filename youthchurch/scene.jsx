// scene.jsx — Church metaverse environment (sanctuary) + worship stage
// Exports: ChurchScene, WorshipScene
// Renders the immersive dark-sanctuary backdrop: stained-glass arch window,
// glowing cross, volumetric godrays, perspective floor, drifting dust.

function GodRays({ count = 5 }) {
  const rays = [];
  // fan of light beams emanating from the window high-center
  const spread = [-34, -18, -4, 12, 28, 44];
  for (let i = 0; i < count; i++) {
    const rot = spread[i] ?? (i * 14 - 30);
    rays.push(
      <div
        key={i}
        className="godray"
        style={{
          transform: `translateX(-50%) rotate(${rot}deg)`,
          animationDelay: `${i * 1.3}s`,
          opacity: 0.5 - Math.abs(rot) / 160,
        }}
      />
    );
  }
  return <div className="godrays" aria-hidden="true">{rays}</div>;
}

function StainedWindow() {
  // gothic pointed-arch window with jewel-tone glass panes
  return (
    <div className="window-wrap" aria-hidden="true">
      <div className="window-glow" />
      <div className="window">
        <div className="window-glass">
          <div className="pane p1" />
          <div className="pane p2" />
          <div className="pane p3" />
          <div className="pane p4" />
          <div className="pane p5" />
          <div className="pane p6" />
        </div>
        <div className="mullion-v" />
        <div className="mullion-h" />
        <div className="window-frame" />
      </div>
    </div>
  );
}

function Cross() {
  return (
    <div className="cross-wrap" aria-hidden="true">
      <div className="cross-halo" />
      <div className="cross">
        <div className="cross-v" />
        <div className="cross-h" />
        <div className="cross-core" />
      </div>
    </div>
  );
}

function Dust({ count = 26 }) {
  const dots = [];
  for (let i = 0; i < count; i++) {
    const left = Math.random() * 100;
    const top = 8 + Math.random() * 64;
    const size = 1 + Math.random() * 2.6;
    const dur = 9 + Math.random() * 12;
    dots.push(
      <span
        key={i}
        className="dust"
        style={{
          left: `${left}%`,
          top: `${top}%`,
          width: size,
          height: size,
          animationDuration: `${dur}s`,
          animationDelay: `${-Math.random() * dur}s`,
          opacity: 0.15 + Math.random() * 0.4,
        }}
      />
    );
  }
  return <div className="dustfield" aria-hidden="true">{dots}</div>;
}

function ChurchScene({ godrays = true, children }) {
  return (
    <div className="scene sanctuary">
      <div className="scene-sky" />
      <div className="arches arch-left" />
      <div className="arches arch-right" />
      <StainedWindow />
      <Cross />
      {godrays && <GodRays />}
      <div className="floor">
        <div className="floor-grid" />
        <div className="floor-pool" />
      </div>
      <Dust />
      <div className="scene-vignette" />
      {children}
    </div>
  );
}

function WorshipScene({ children }) {
  return (
    <div className="scene worship">
      <div className="scene-sky worship-sky" />
      <div className="stage-haze" />
      {/* stage spotlights */}
      <div className="spot s1" />
      <div className="spot s2" />
      <div className="spot s3" />
      <Cross />
      {/* stage silhouette band */}
      <div className="stage">
        <div className="band-member bm1" />
        <div className="band-member bm2" />
        <div className="band-member bm3" />
        <div className="stage-edge" />
      </div>
      <Dust count={18} />
      <div className="scene-vignette" />
      {children}
    </div>
  );
}

Object.assign(window, { ChurchScene, WorshipScene, GodRays, StainedWindow, Cross, Dust });
