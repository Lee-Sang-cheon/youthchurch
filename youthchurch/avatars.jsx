// avatars.jsx — user presence: stylized avatars, name tags, profile card, reactions
// Exports: Avatar, AvatarLayer, ProfileCard, ReactionBurst, SelfAvatar

function Avatar({ user, style: avatarStyle = 'blob', onTap, selected, idleSeed = 0 }) {
  const c = user.color;
  const c2 = user.color2 || user.color;
  return (
    <button
      className={`avatar avatar-${avatarStyle} ${selected ? 'is-selected' : ''}`}
      onClick={(e) => { e.stopPropagation(); onTap && onTap(user); }}
      style={{
        left: `${user.x}%`,
        bottom: `${user.y}%`,
        '--ac': c,
        '--ac2': c2,
        transform: `translateX(-50%) scale(${user.scale ?? 1})`,
        zIndex: Math.round((100 - (user.y ?? 20)) ),
        animationDelay: `${idleSeed * -0.7}s`,
      }}
    >
      <span className="av-pool" />
      <span className="av-tag">
        {user.live && <span className="av-live" />}
        {user.name}
      </span>
      <span className="av-body">
        <span className="av-head" />
        <span className="av-torso" />
        <span className="av-glow" />
      </span>
    </button>
  );
}

function SelfAvatar({ pos, style: avatarStyle = 'blob' }) {
  return (
    <div
      className={`avatar avatar-${avatarStyle} is-self`}
      style={{
        left: `${pos.x}%`,
        bottom: `${pos.y}%`,
        '--ac': '#ffe9b8',
        '--ac2': '#ffb44d',
        transform: 'translateX(-50%)',
        zIndex: 95,
      }}
    >
      <span className="av-pool self-pool" />
      <span className="av-tag self-tag">나</span>
      <span className="av-body">
        <span className="av-head" />
        <span className="av-torso" />
        <span className="av-glow" />
      </span>
      <span className="self-ring" />
    </div>
  );
}

function AvatarLayer({ users, avatarStyle, onTapUser, selectedId }) {
  return (
    <div className="avatar-layer">
      {users.map((u, i) => (
        <Avatar
          key={u.id}
          user={u}
          style={avatarStyle}
          idleSeed={i + 1}
          selected={selectedId === u.id}
          onTap={onTapUser}
        />
      ))}
    </div>
  );
}

function ProfileCard({ user, onClose, onGreet }) {
  if (!user) return null;
  return (
    <div className="profile-sheet" onClick={onClose}>
      <div className="profile-card glass" onClick={(e) => e.stopPropagation()}>
        <div className="profile-top">
          <span
            className="profile-ava"
            style={{ background: `radial-gradient(circle at 35% 28%, ${user.color2 || '#fff'}, ${user.color})` }}
          />
          <div className="profile-meta">
            <div className="profile-name">
              {user.name}
              {user.live && <span className="badge-live">LIVE</span>}
            </div>
            <div className="profile-role">{user.role}</div>
          </div>
          <button className="profile-x" onClick={onClose} aria-label="닫기">✕</button>
        </div>
        <div className="profile-status">“{user.status}”</div>
        <div className="profile-actions">
          <button className="pa pa-primary" onClick={() => onGreet(user)}>
            <span className="pa-emoji">👋</span> 인사하기
          </button>
          <button className="pa pa-ghost" onClick={() => onGreet(user, '🙏')}>🙏</button>
          <button className="pa pa-ghost" onClick={() => onGreet(user, '✨')}>✨</button>
          <button className="pa pa-ghost" onClick={() => onGreet(user, '❤️')}>❤️</button>
        </div>
      </div>
    </div>
  );
}

function ReactionBurst({ items }) {
  return (
    <div className="reaction-layer" aria-hidden="true">
      {items.map((r) => (
        <span
          key={r.id}
          className="reaction"
          style={{ left: `${r.x}%`, bottom: `${r.y}%`, '--drift': `${r.drift}px` }}
        >
          {r.emoji}
        </span>
      ))}
    </div>
  );
}

Object.assign(window, { Avatar, SelfAvatar, AvatarLayer, ProfileCard, ReactionBurst });
