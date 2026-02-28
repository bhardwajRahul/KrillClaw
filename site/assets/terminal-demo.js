/**
 * KrillClaw Terminal Demo — Scripted terminal replay with typing animation.
 * Two side-by-side demos showing before/after AI agent intelligence.
 * Auto-plays on scroll-into-view, with replay button.
 */
(function () {
  'use strict';

  var CMD_SPEED = 40;   // ms per char for commands
  var OUT_SPEED = 12;   // ms per char for output
  var LINE_PAUSE = 400; // ms between lines
  var SECTION_PAUSE = 800;

  var demos = {
    car: {
      title: 'The 2018 Car ECU',
      before: [
        { type: 'cmd', text: '> read_sensor temperature_engine' },
        { type: 'out', text: '  Engine: 210°F [WARNING]' },
        { type: 'cmd', text: '> read_sensor coolant_level' },
        { type: 'out', text: '  Coolant: LOW [ALERT]' },
        { type: 'cmd', text: '> ???' },
        { type: 'out', text: '  No intelligence. Just alarms.' },
      ],
      after: [
        { type: 'cmd', text: '> krillclaw --profile iot "engine temp 210°F, rising"' },
        { type: 'agent', text: '  [Agent] Reading sensor history...' },
        { type: 'agent', text: '  [Agent] Temp rose 40°F in 2 minutes.' },
        { type: 'agent', text: '  [Agent] Cross-referencing coolant... LOW.' },
        { type: 'agent', text: '  [Agent] ⚠ Reduce engine load immediately.' },
        { type: 'agent', text: '  [Agent] Coolant leak probable.' },
        { type: 'agent', text: '  [Agent] → Navigate to nearest service.' },
        { type: 'agent', text: '  [Agent] Setting dashboard: COOLANT SERVICE' },
      ],
    },
    elevator: {
      title: 'Smart Elevator Controller',
      before: [
        { type: 'cmd', text: '> floor_request 3' },
        { type: 'out', text: '  Moving to floor 3. ETA: 45 seconds.' },
        { type: 'cmd', text: '> floor_request 12' },
        { type: 'out', text: '  Moving to floor 12. ETA: 90 seconds.' },
        { type: 'out', text: '  Fixed schedule. No awareness.' },
      ],
      after: [
        { type: 'cmd', text: '> krillclaw --profile iot "optimize for morning rush"' },
        { type: 'agent', text: '  [Agent] Analyzing usage from KV store...' },
        { type: 'agent', text: '  [Agent] Peak: floors 1→8,12,15 at 8:30-9:15.' },
        { type: 'agent', text: '  [Agent] Time: 8:25 AM. Pre-positioning.' },
        { type: 'agent', text: '  [Agent] Express mode: lobby → 8, 12, 15.' },
        { type: 'agent', text: '  [Agent] Disabling door-hold floors 2-7.' },
        { type: 'agent', text: '  [Agent] ✓ Wait time reduction: ~40%' },
      ],
    },
  };

  function createTerminal(container, lines, isBefore, onDone) {
    container.innerHTML = '';
    container.className = 'term-panel' + (isBefore ? ' term-before' : ' term-after');
    var cursor = document.createElement('span');
    cursor.className = 'term-cursor';
    cursor.textContent = '█';
    var currentLine = 0;

    function typeLine() {
      if (currentLine >= lines.length) {
        cursor.remove();
        if (onDone) onDone();
        return;
      }
      var line = lines[currentLine];
      var el = document.createElement('div');
      el.className = 'term-line term-' + line.type;
      container.appendChild(el);
      el.appendChild(cursor);

      var text = line.text;
      var i = 0;
      var speed = line.type === 'cmd' ? CMD_SPEED : OUT_SPEED;

      function typeChar() {
        if (i < text.length) {
          // Insert char before cursor
          cursor.before(document.createTextNode(text[i]));
          i++;
          setTimeout(typeChar, speed);
        } else {
          currentLine++;
          var pause = currentLine < lines.length ? LINE_PAUSE : 0;
          setTimeout(typeLine, pause);
        }
      }
      typeChar();
    }

    setTimeout(typeLine, isBefore ? 200 : SECTION_PAUSE);
  }

  function initDemo(id) {
    var demo = demos[id];
    if (!demo) return;

    var section = document.getElementById('demo-' + id);
    if (!section) return;

    var beforePanel = section.querySelector('.term-before-wrap');
    var afterPanel = section.querySelector('.term-after-wrap');
    var replayBtn = section.querySelector('.term-replay');
    var started = false;

    function play() {
      if (replayBtn) replayBtn.style.display = 'none';
      createTerminal(beforePanel, demo.before, true, function () {
        createTerminal(afterPanel, demo.after, false, function () {
          if (replayBtn) replayBtn.style.display = 'inline-block';
        });
      });
    }

    // Auto-play on scroll into view
    var observer = new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting && !started) {
        started = true;
        play();
      }
    }, { threshold: 0.3 });
    observer.observe(section);

    // Replay button
    if (replayBtn) {
      replayBtn.addEventListener('click', function () {
        started = true;
        play();
      });
    }
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      initDemo('car');
      initDemo('elevator');
    });
  } else {
    initDemo('car');
    initDemo('elevator');
  }
})();
