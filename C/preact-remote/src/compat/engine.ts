/**
 * Engine compatibility layer for the remote preact project.
 * Bridges JS ↔ C++ via Sciter's globalThis injected objects.
 *
 * In-engine: globalThis.Engine is injected by CHtmlEngine::Register("Engine", ...)
 * In-browser: provides console-logging mock fallbacks for development.
 */

interface EngineInterface {
  Subscribe(event: string, callback: (...args: any[]) => void): void;
  GetDatabaseLocation(): string;
  OpenModal(type: string, callback: () => void): void;
}

let Engine: EngineInterface;

if (typeof (globalThis as any).Engine === "undefined") {
  Engine = {
    Subscribe: (event: string, callback: (...args: any[]) => void) => {
      console.log("[Engine Mock] Subscribe:", event, callback);
    },
    GetDatabaseLocation: () => "app-data.db",
    OpenModal: (_type: string, callback: () => void) => {
      callback();
    },
  };
} else {
  Engine = (globalThis as any).Engine as EngineInterface;
}

export { Engine };

/**
 * Calls the engine to open another user's profile.
 * In-engine: globalThis.GameNav.ViewProfile(username) triggers
 * HtmlEngine.Invoke(L"ViewUserProfile", username) which fires
 * the callback in the main preact widget, navigating to the profile page.
 */

interface GameNavInterface {
  ViewProfile(username: string): void;
  ViewLadder(): void;
  ViewPatchNotes(): void;
  ViewPatchNotesById(patchId: string): void;
  OpenURL(url: string): void;
  OpenHoNWeb(redirectPath?: string): void;
}

let GameNav: GameNavInterface;

if (typeof (globalThis as any).GameNav === "undefined") {
  GameNav = {
    ViewProfile: (username: string) => {
      console.log("[GameNav Mock] ViewProfile:", username);
      alert(`Would open profile for: ${username}`);
    },
    ViewLadder: () => {
      console.log("[GameNav Mock] ViewLadder");
    },
    ViewPatchNotes: () => {
      console.log("[GameNav Mock] ViewPatchNotes");
    },
    ViewPatchNotesById: (patchId: string) => {
      console.log("[GameNav Mock] ViewPatchNotesById:", patchId);
    },
    OpenURL: (url: string) => {
      console.log("[GameNav Mock] OpenURL:", url);
      window.open(url, '_blank');
    },
    OpenHoNWeb: (redirectPath?: string) => {
      console.log("[GameNav Mock] OpenHoNWeb:", redirectPath);
      window.open(`https://heroesofnewerth.com${redirectPath || '/hero-vote'}`, '_blank');
    },
  };
} else {
  GameNav = (globalThis as any).GameNav as GameNavInterface;
}

export { GameNav };
