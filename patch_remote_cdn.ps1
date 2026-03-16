function Invoke-RemoteCdnPatch {
    param(
        [string]$JuvioRoot = (Join-Path $env:LOCALAPPDATA "Juvio")
    )

    $remoteRoot = Join-Path $JuvioRoot "remote\cdn"
    $indexJs = Join-Path $remoteRoot "index.js"
    $indexHtml = Join-Path $remoteRoot "index.html"
    if ((-not (Test-Path $indexJs)) -or (-not (Test-Path $indexHtml))) {
        return $false
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $jsText = [System.IO.File]::ReadAllText($indexJs, [System.Text.Encoding]::UTF8)
    $jsOriginal = $jsText
    $htmlText = [System.IO.File]::ReadAllText($indexHtml, [System.Text.Encoding]::UTF8)
    $htmlOriginal = $htmlText

    $replacements = @(
        [pscustomobject]@{ Source = 'children:"Message of the Day"'; Target = 'children:"\u0421\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u0435 \u0434\u043d\u044f"' }
        [pscustomobject]@{ Source = 'children:"Live This Weekend"'; Target = 'children:"\u0423\u0436\u0435 \u0432 \u044d\u0442\u0438 \u0432\u044b\u0445\u043e\u0434\u043d\u044b\u0435"' }
        [pscustomobject]@{ Source = 'label:"Watch on Twitch"'; Target = 'label:"\u0421\u043c\u043e\u0442\u0440\u0435\u0442\u044c \u043d\u0430 Twitch"' }
        [pscustomobject]@{ Source = 'label:"View Announcement"'; Target = 'label:"\u041e\u0442\u043a\u0440\u044b\u0442\u044c \u0430\u043d\u043e\u043d\u0441"' }
        [pscustomobject]@{ Source = 'children:["Announcement",i(U,{})]'; Target = 'children:["\u0410\u043d\u043e\u043d\u0441",i(U,{})]' }
        [pscustomobject]@{ Source = 'children:"Latest Updates"'; Target = 'children:"\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0438\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f"' }
        [pscustomobject]@{ Source = 'children:"Quick Links"'; Target = 'children:"\u0411\u044b\u0441\u0442\u0440\u044b\u0435 \u0441\u0441\u044b\u043b\u043a\u0438"' }
        [pscustomobject]@{ Source = 'children:"Join the community"'; Target = 'children:"\u041f\u0440\u0438\u0441\u043e\u0435\u0434\u0438\u043d\u044f\u0439\u0442\u0435\u0441\u044c \u043a \u0441\u043e\u043e\u0431\u0449\u0435\u0441\u0442\u0432\u0443"' }
        [pscustomobject]@{ Source = 'children:"Website"'; Target = 'children:"\u0421\u0430\u0439\u0442"' }
        [pscustomobject]@{ Source = 'children:"Support"'; Target = 'children:"\u041f\u043e\u0434\u0434\u0435\u0440\u0436\u043a\u0430"' }
        [pscustomobject]@{ Source = 'children:"Get help"'; Target = 'children:"\u041f\u043e\u043b\u0443\u0447\u0438\u0442\u044c \u043f\u043e\u043c\u043e\u0449\u044c"' }
        [pscustomobject]@{ Source = 'label:"Read Patch Notes"'; Target = 'label:"\u0421\u043f\u0438\u0441\u043e\u043a \u0438\u0437\u043c\u0435\u043d\u0435\u043d\u0438\u0439"' }
        [pscustomobject]@{ Source = 'label:"Vote Now"'; Target = 'label:"\u0413\u043e\u043b\u043e\u0441\u043e\u0432\u0430\u0442\u044c"' }
        [pscustomobject]@{ Source = 'tag:"Tournament"'; Target = 'tag:"\u0422\u0443\u0440\u043d\u0438\u0440"' }
        [pscustomobject]@{ Source = 'tag:"Event"'; Target = 'tag:"\u0421\u043e\u0431\u044b\u0442\u0438\u0435"' }
        [pscustomobject]@{ Source = 'tag:"Patch"'; Target = 'tag:"\u041f\u0430\u0442\u0447"' }
    )

    foreach ($pair in $replacements) {
        $jsText = $jsText.Replace($pair.Source, $pair.Target)
    }

    $domPatch = @'
    <script>
      (function () {
        if (window.__honRuDomPatch) return;
        window.__honRuDomPatch = true;

        const exact = new Map([
          ["Message of the Day", "\u0421\u043e\u043e\u0431\u0449\u0435\u043d\u0438\u0435 \u0434\u043d\u044f"],
          ["Latest Updates", "\u041f\u043e\u0441\u043b\u0435\u0434\u043d\u0438\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f"],
          ["Quick Links", "\u0411\u044b\u0441\u0442\u0440\u044b\u0435 \u0441\u0441\u044b\u043b\u043a\u0438"],
          ["Join the community", "\u041f\u0440\u0438\u0441\u043e\u0435\u0434\u0438\u043d\u044f\u0439\u0442\u0435\u0441\u044c \u043a \u0441\u043e\u043e\u0431\u0449\u0435\u0441\u0442\u0432\u0443"],
          ["Website", "\u0421\u0430\u0439\u0442"],
          ["Support", "\u041f\u043e\u0434\u0434\u0435\u0440\u0436\u043a\u0430"],
          ["Get help", "\u041f\u043e\u043b\u0443\u0447\u0438\u0442\u044c \u043f\u043e\u043c\u043e\u0449\u044c"],
          ["Watch on Twitch", "\u0421\u043c\u043e\u0442\u0440\u0435\u0442\u044c \u043d\u0430 Twitch"],
          ["Announcement", "\u0410\u043d\u043e\u043d\u0441"],
          ["Live This Weekend", "\u0423\u0436\u0435 \u0432 \u044d\u0442\u0438 \u0432\u044b\u0445\u043e\u0434\u043d\u044b\u0435"],
          ["A new update is available!", "\u0414\u043e\u0441\u0442\u0443\u043f\u043d\u043e \u043d\u043e\u0432\u043e\u0435 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0435!"],
          ["Downloading update", "\u0417\u0430\u0433\u0440\u0443\u0437\u043a\u0430 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f"],
          ["Check for update", "\u041f\u0440\u043e\u0432\u0435\u0440\u0438\u0442\u044c \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f"],
          ["Update now", "\u041e\u0431\u043d\u043e\u0432\u0438\u0442\u044c \u0441\u0435\u0439\u0447\u0430\u0441"],
          ["Remember Me", "\u0417\u0430\u043f\u043e\u043c\u043d\u0438\u0442\u044c \u043c\u0435\u043d\u044f"],
          ["Login", "\u0410\u0432\u0442\u043e\u0440\u0438\u0437\u043e\u0432\u0430\u0442\u044c\u0441\u044f"],
          ["Password", "\u041f\u0430\u0440\u043e\u043b\u044c"],
          ["Username", "\u041b\u043e\u0433\u0438\u043d"],
          ["Player discretion is advised", "\u041d\u0430 \u0443\u0441\u043c\u043e\u0442\u0440\u0435\u043d\u0438\u0435 \u0438\u0433\u0440\u043e\u043a\u0430"],
          ["Some content in this game may offend you", "\u041d\u0435\u043a\u043e\u0442\u043e\u0440\u044b\u0435 \u043c\u0430\u0442\u0435\u0440\u0438\u0430\u043b\u044b \u0432 \u0438\u0433\u0440\u0435 \u043c\u043e\u0433\u0443\u0442 \u0432\u0430\u0441 \u043e\u0441\u043a\u043e\u0440\u0431\u0438\u0442\u044c"],
          ["Tournament", "\u0422\u0443\u0440\u043d\u0438\u0440"],
          ["Event", "\u0421\u043e\u0431\u044b\u0442\u0438\u0435"],
          ["Patch", "\u041f\u0430\u0442\u0447"]
        ]);

        const prefixes = [
          ["Number of active download jobs:", "\u0410\u043a\u0442\u0438\u0432\u043d\u044b\u0445 \u0437\u0430\u0433\u0440\u0443\u0437\u043e\u043a:"],
          ["Current download size:", "\u0420\u0430\u0437\u043c\u0435\u0440 \u0437\u0430\u0433\u0440\u0443\u0437\u043a\u0438:"],
          ["Downloaded:", "\u0417\u0430\u0433\u0440\u0443\u0436\u0435\u043d\u043e:"],
          ["Download speed:", "\u0421\u043a\u043e\u0440\u043e\u0441\u0442\u044c \u0437\u0430\u0433\u0440\u0443\u0437\u043a\u0438:"],
          ["Version:", "\u0412\u0435\u0440\u0441\u0438\u044f:"],
          ["Update size:", "\u0420\u0430\u0437\u043c\u0435\u0440 \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f:"]
        ];

        function translateValue(value) {
          if (!value) return value;
          const trimmed = value.trim();
          if (!trimmed) return value;

          if (exact.has(trimmed)) {
            return value.replace(trimmed, exact.get(trimmed));
          }

          for (const pair of prefixes) {
            const source = pair[0];
            const target = pair[1];
            if (trimmed.indexOf(source) === 0) {
              return value.replace(source, target);
            }
          }

          return value;
        }

        function patchElement(el) {
          if (!el || el.nodeType !== 1) return;

          const attrs = ["placeholder", "title", "aria-label", "value"];
          for (const attr of attrs) {
            const current = el.getAttribute && el.getAttribute(attr);
            if (current) {
              const next = translateValue(current);
              if (next !== current) {
                el.setAttribute(attr, next);
                if (attr === "value" && "value" in el) {
                  el.value = next;
                }
              }
            }
          }

          if (el.tagName === "INPUT" || el.tagName === "TEXTAREA" || el.tagName === "BUTTON") {
            if (typeof el.value === "string" && el.value) {
              const nextValue = translateValue(el.value);
              if (nextValue !== el.value) {
                el.value = nextValue;
              }
            }
          }
        }

        function patchTextNode(node) {
          if (!node || node.nodeType !== 3 || !node.nodeValue) return;
          const next = translateValue(node.nodeValue);
          if (next !== node.nodeValue) {
            node.nodeValue = next;
          }
        }

        function patchTree(root) {
          if (!root) return;
          if (root.nodeType === 3) {
            patchTextNode(root);
            return;
          }
          if (root.nodeType !== 1 && root.nodeType !== 9) return;

          if (root.nodeType === 1) {
            patchElement(root);
          }

          const walker = document.createTreeWalker(root, NodeFilter.SHOW_ALL, null);
          let current = walker.currentNode;
          while (current) {
            if (current.nodeType === 3) {
              patchTextNode(current);
            } else if (current.nodeType === 1) {
              patchElement(current);
            }
            current = walker.nextNode();
          }
        }

        function run() {
          try {
            patchTree(document.body || document.documentElement);
          } catch (err) {
            console.log("[HoN_RU_DOM]", err && err.message ? err.message : err);
          }
        }

        if (document.readyState === "loading") {
          document.addEventListener("DOMContentLoaded", run, { once: true });
        } else {
          run();
        }

        const observer = new MutationObserver(function (mutations) {
          for (const mutation of mutations) {
            if (mutation.type === "characterData") {
              patchTextNode(mutation.target);
              continue;
            }
            if (mutation.type === "attributes") {
              patchElement(mutation.target);
              continue;
            }
            for (const node of mutation.addedNodes) {
              patchTree(node);
            }
          }
        });

        observer.observe(document.documentElement || document, {
          childList: true,
          subtree: true,
          characterData: true,
          attributes: true,
          attributeFilter: ["placeholder", "title", "aria-label", "value"]
        });

        setInterval(run, 1500);
      })();
    </script>
'@

    if ($htmlText -notmatch '__honRuDomPatch') {
        $htmlText = $htmlText.Replace('</head>', ($domPatch + "`r`n  </head>"))
    }

    $changed = $false

    $backupPath = Join-Path $remoteRoot "index.js.bak_hon_ru"
    if (($jsText -ne $jsOriginal) -and (-not (Test-Path $backupPath))) {
        [System.IO.File]::WriteAllText($backupPath, $jsOriginal, $utf8NoBom)
    }

    $htmlBackupPath = Join-Path $remoteRoot "index.html.bak_hon_ru"
    if (($htmlText -ne $htmlOriginal) -and (-not (Test-Path $htmlBackupPath))) {
        [System.IO.File]::WriteAllText($htmlBackupPath, $htmlOriginal, $utf8NoBom)
    }

    if ($jsText -ne $jsOriginal) {
        [System.IO.File]::WriteAllText($indexJs, $jsText, $utf8NoBom)
        $changed = $true
    }

    if ($htmlText -ne $htmlOriginal) {
        [System.IO.File]::WriteAllText($indexHtml, $htmlText, $utf8NoBom)
        $changed = $true
    }

    return $changed
}
