import './Motd.css';
import { GameNav } from '../compat/engine';

// ─── SVG Icons (inline to avoid asset loading complexity) ───

const MegaphoneIcon = () => (
  <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <path d="M20 2 L20 22 L12 18 L4 18 L2 18 L2 6 L4 6 L12 6 L20 2 Z M18 6.27 L14.46 8 L4 8 L4 16 L14.46 16 L18 17.73 L18 6.27 Z M22 9 L22 15 L24 15 L24 9 L22 9 Z"/>
  </svg>
);

const ArrowRightIcon = () => (
  <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <path d="M12 4l-1.41 1.41L16.17 11H4v2h12.17l-5.58 5.59L12 20l8-8-8-8z"/>
  </svg>
);

const UserIcon = () => (
  <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <path d="M12 12c2.7 0 4.8-2.1 4.8-4.8S14.7 2.4 12 2.4 7.2 4.5 7.2 7.2 9.3 12 12 12zm0 2.4c-3.2 0-9.6 1.6-9.6 4.8v2.4h19.2v-2.4c0-3.2-6.4-4.8-9.6-4.8z"/>
  </svg>
);

const DiscordIcon = () => (
  <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <path d="M20.317 4.37a19.791 19.791 0 00-4.885-1.515.074.074 0 00-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 00-5.487 0 12.64 12.64 0 00-.617-1.25.077.077 0 00-.079-.037A19.736 19.736 0 003.677 4.37a.07.07 0 00-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 00.031.057 19.9 19.9 0 005.993 3.03.078.078 0 00.084-.028c.462-.63.874-1.295 1.226-1.994a.076.076 0 00-.041-.106 13.107 13.107 0 01-1.872-.892.077.077 0 01-.008-.128 10.2 10.2 0 00.372-.292.074.074 0 01.077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 01.078.01c.12.098.246.198.373.292a.077.077 0 01-.006.127 12.299 12.299 0 01-1.873.892.077.077 0 00-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 00.084.028 19.839 19.839 0 006.002-3.03.077.077 0 00.032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 00-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.095 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.095 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z"/>
  </svg>
);

const GlobeIcon = () => (
  <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/>
  </svg>
);

const HeartIcon = () => (
  <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
  </svg>
);

// ─── Player Name Link ──────────────────────────

function PlayerLink({ username }: { username: string }) {
  const handleClick = () => {
    GameNav.ViewProfile(username);
  };

  return (
    <span class="player-link" onClick={handleClick} title={`View ${username}'s profile`}>
      <UserIcon />
      {username}
    </span>
  );
}

// ─── News Data ─────────────────────────────────

interface NewsItem {
  id: number;
  tag: string;
  tagClass: string;
  accentClass: string;
  title: string;
  text: string;
  timestamp: string;
  patchId?: string;
  cta?: { label: string; action?: () => void; variant?: string };
  playerMention?: string;
}

const newsItems: NewsItem[] = [
  {
    id: 0,
    tag: '\u0421\u043e\u0431\u044b\u0442\u0438\u0435',
    tagClass: 'motd-card-tag--event',
    accentClass: 'motd-card-accent--gold',
    title: 'Hero Voting — Choose the Next Hero',
    text: 'Hero Voting begins March 2nd! Cast your vote to decide which hero gets remastered next. Every vote counts — shape the future of Newerth.',
    timestamp: 'Mar 2',
    cta: { label: '\u0413\u043e\u043b\u043e\u0441\u043e\u0432\u0430\u0442\u044c', action: () => openHeroVoting(), variant: 'orange' },
  },
  {
    id: 1,
    tag: '\u041f\u0430\u0442\u0447',
    tagClass: 'motd-card-tag--balance',
    accentClass: 'motd-card-accent--orange',
    title: 'Patch 0.9.4 — Ravenor Unleashed',
    text: 'Role Priorities, Death Cost Overhaul, Report Penalties Live, and Harsher Dodge Penalties.',
    timestamp: 'Feb 24',
    patchId: '0.9.4',
    cta: { label: '\u0421\u043f\u0438\u0441\u043e\u043a \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u0439', action: () => GameNav.ViewPatchNotesById('0.9.4') },
  },
  {
    id: 2,
    tag: '\u041f\u0430\u0442\u0447',
    tagClass: 'motd-card-tag--feature',
    accentClass: 'motd-card-accent--green',
    title: 'Patch 0.9.3b — In-Game Patch Notes & Replays',
    text: 'In-Game Patch Notes viewer, Replay Downloads, Post-Match Summary Overhaul, and Bug Fixes.',
    timestamp: 'Feb 11',
    patchId: '0.9.3b',
    cta: { label: '\u0421\u043f\u0438\u0441\u043e\u043a \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u0439', action: () => GameNav.ViewPatchNotesById('0.9.3b') },
  },
  {
    id: 3,
    tag: '\u041f\u0430\u0442\u0447',
    tagClass: 'motd-card-tag--feature',
    accentClass: 'motd-card-accent--green',
    title: 'Patch 0.9.3 — Role Queue & Revenant',
    text: 'Role Queue system, Kick System replaced with new penalties, Penalty Points Reset, and new hero Revenant joins the battle.',
    timestamp: 'Feb 7',
    patchId: '0.9.3',
    cta: { label: '\u0421\u043f\u0438\u0441\u043e\u043a \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u0439', action: () => GameNav.ViewPatchNotesById('0.9.3') },
  },
  {
    id: 4,
    tag: '\u041f\u0430\u0442\u0447',
    tagClass: 'motd-card-tag--event',
    accentClass: 'motd-card-accent--gold',
    title: 'Patch 0.9.2 — Revamped Guide System',
    text: 'Revamped Guide System, Midwars Map Update, Announcer Mute Options, and Winter Theme Farewell.',
    timestamp: 'Jan 31',
    patchId: '0.9.2',
    cta: { label: '\u0421\u043f\u0438\u0441\u043e\u043a \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u0439', action: () => GameNav.ViewPatchNotesById('0.9.2') },
  },
  {
    id: 5,
    tag: '\u041f\u0430\u0442\u0447',
    tagClass: 'motd-card-tag--community',
    accentClass: 'motd-card-accent--cyan',
    title: 'Patch 0.9.1 — Master of Arms',
    text: 'Master of Arms arrives with his versatile weapon kit, hero balance updates, and quality-of-life improvements.',
    timestamp: 'Jan 25',
    patchId: '0.9.1',
    cta: { label: '\u0421\u043f\u0438\u0441\u043e\u043a \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u0439', action: () => GameNav.ViewPatchNotesById('0.9.1') },
  },
  {
    id: 6,
    tag: '\u041f\u0430\u0442\u0447',
    tagClass: 'motd-card-tag--balance',
    accentClass: 'motd-card-accent--orange',
    title: 'Patch 0.9.0 — Ranked Midwars',
    text: 'Ranked Midwars, Notification System Overhaul, and Immediate Match Submission.',
    timestamp: 'Jan 19',
    patchId: '0.9.0',
    cta: { label: '\u0421\u043f\u0438\u0441\u043e\u043a \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u0439', action: () => GameNav.ViewPatchNotesById('0.9.0') },
  },
];

// ─── Hero Voting ───────────────────────────────

const HERO_VOTING_URL = '/hero-vote';

function openHeroVoting() {
  GameNav.OpenHoNWeb(HERO_VOTING_URL);
}

// ─── Main Component ────────────────────────────

export function Motd() {
  return (
    <div class="motd">
      {/* Header (pinned) */}
      <div class="motd-header">
        <div class="motd-header-icon">
          <MegaphoneIcon />
        </div>
        <div class="motd-header-title">\u0421\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u0435 \u0434\u043d\u044f</div>
      </div>

      {/* Scrollable content */}
      <div class="motd-body">
      {/* Featured Banner */}
      <div class="motd-banner" onClick={openHeroVoting}>
        <div class="motd-banner-tag">\u0421\u043a\u043e\u0440\u043e</div>
        <div class="motd-banner-row">
          <div class="motd-banner-content">
            <div class="motd-banner-title">Hero Voting begins March 2nd</div>
            <div class="motd-banner-subtitle">Vote for the next hero to be remastered. Your voice shapes the future of Newerth.</div>
          </div>
          <button class="motd-cta motd-cta--small motd-cta--orange motd-banner-btn" onClick={(e) => { e.stopPropagation(); openHeroVoting(); }}>
            \u0413\u043e\u043b\u043e\u0441\u043e\u0432\u0430\u0442\u044c
            <ArrowRightIcon />
          </button>
        </div>
      </div>

      {/* News Cards */}
      <div class="motd-section-title">\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0438\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f</div>
      <div class="motd-cards">
        {newsItems.map((item) => (
          <div key={item.id} class="motd-card">
            <div class={`motd-card-accent ${item.accentClass}`} />
            <div class="motd-card-body">
              <div class="motd-card-header">
                <span class={`motd-card-tag ${item.tagClass}`}>{item.tag}</span>
                <span class="motd-card-timestamp">{item.timestamp}</span>
              </div>
              <div class="motd-card-title">{item.title}</div>
              <div class="motd-card-text">
                {item.text}
                {item.playerMention && (
                  <>
                    Check out <PlayerLink username={item.playerMention} />'s incredible plays from
                    last week's tournament. Their Pebbles performance set a new record for most kills
                    in a competitive match!
                  </>
                )}
              </div>
              {item.cta && (
                <button
                  class={`motd-cta motd-cta--small ${item.cta.variant === 'orange' ? 'motd-cta--orange' : ''}`}
                  onClick={item.cta.action}
                >
                  {item.cta.label}
                  <ArrowRightIcon />
                </button>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* \u0411\u044b\u0441\u0442\u0440\u044b\u0435 \u0441\u0441\u044b\u043b\u043a\u0438 */}
      <div class="motd-section-title">\u0411\u044b\u0441\u0442\u0440\u044b\u0435 \u0441\u0441\u044b\u043b\u043a\u0438</div>
      <div class="motd-links">
        <div class="motd-link" onClick={() => GameNav.OpenURL('https://discord.gg/HoNReborn')}>
          <div class="motd-link-icon motd-link-icon--discord">
            <DiscordIcon />
          </div>
          <div>
            <div class="motd-link-label">Discord</div>
            <div class="motd-link-desc">\u041f\u0440\u0438\u0441\u043e\u0435\u0434\u0438\u043d\u044f\u0439\u0442\u0435\u0441\u044c \u043a \u0441\u043e\u043e\u0431\u0449\u0435\u0441\u0442\u0432\u0443</div>
          </div>
        </div>
        <div class="motd-link" onClick={() => GameNav.OpenHoNWeb('/')}>
          <div class="motd-link-icon motd-link-icon--web">
            <GlobeIcon />
          </div>
          <div>
            <div class="motd-link-label">\u0421\u0430\u0439\u0442</div>
            <div class="motd-link-desc">heroesofnewerth.com</div>
          </div>
        </div>
        <div class="motd-link" onClick={() => GameNav.OpenURL('https://app.juvio.com/support')}>
          <div class="motd-link-icon motd-link-icon--support">
            <HeartIcon />
          </div>
          <div>
            <div class="motd-link-label">\u041f\u043e\u0434\u0434\u0435\u0440\u0436\u043a\u0430</div>
            <div class="motd-link-desc">\u041f\u043e\u043b\u0443\u0447\u0438\u0442\u044c \u043f\u043e\u043c\u043e\u0449\u044c</div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div class="motd-footer">
        &copy; 2026 Kongor Studios. All rights reserved.
      </div>
      </div>{/* end motd-body */}
    </div>
  );
}
