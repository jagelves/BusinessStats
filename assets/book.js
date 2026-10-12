(function () {
  var parts = [
    { re: /^Descriptive/i, key: "describe",    label: "Part I · Describe" },
    { re: /^Regression/i,  key: "regression",  label: "Part II · Relate" },
    { re: /^Probability/i, key: "probability", label: "Part III · Uncertainty" },
    { re: /^(Inference|InfReg)/i, key: "inference", label: "Part IV · Infer" },
    { re: /^Excel/i,       key: "tools",       label: "Appendix · Toolkit" }
  ];
  function init() {
    var file = decodeURIComponent(location.pathname.split("/").pop() || "index.html");
    var part = null;
    for (var i = 0; i < parts.length; i++) if (parts[i].re.test(file)) { part = parts[i]; break; }
    document.body.setAttribute("data-part", part ? part.key : "home");

    var bar = document.createElement("div");
    bar.id = "bs-progress";
    document.body.appendChild(bar);
    var onScroll = function () {
      var h = document.documentElement;
      var max = h.scrollHeight - h.clientHeight;
      bar.style.width = (max > 0 ? (h.scrollTop / max) * 100 : 0) + "%";
    };
    document.addEventListener("scroll", onScroll, { passive: true });
    onScroll();

    if (!part) return;
    var title = document.querySelector("#title-block-header") || document.querySelector("main h1");
    if (!title) return;
    var main = document.querySelector("main");
    var words = (main ? main.innerText : "").split(/\s+/).length;
    var eb = document.createElement("div");
    eb.className = "bs-eyebrow";
    eb.textContent = part.label;
    title.parentNode.insertBefore(eb, title);
    var meta = document.createElement("div");
    meta.className = "bs-meta";
    meta.textContent = Math.max(1, Math.round(words / 230)) + " min read";
    title.parentNode.insertBefore(meta, title.nextSibling);
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
