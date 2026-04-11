import { setModuleUrlResolver } from "@sciter";

setModuleUrlResolver((name, documentDir, sourceDir) => {
  if (name.startsWith('@/')) {
    return '/src/' + name.substring(2);
  }

  if (name.endsWith(".css")) {
    var url;
    if (name.startsWith("./") || name.startsWith("../")) {
      // relative
      url = new URL(name, sourceDir).toString();
    } else {
      // a module
      url = "node_modules/" + name;
    }
    
    document.head.append(
      '<link rel="stylesheet" type="text/css" href="' + url + '">'
    );
    return url;
  }
  return name;
});

document.on("beforeunload", (e) => {
  if (e.target === this) srt.setModuleUrlResolver(null);
});

import * as Storage from "@storage";
import * as Env from "@env";
import * as Sys from "@sys";

const startTime = Sys.hrtime();
globalThis.performance = {
  now: () => {
    const current = Sys.hrtime();
    return Number(current - startTime) / 1_000_000;
  }
};

globalThis.Storage = Storage;
