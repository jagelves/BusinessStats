// Multiple-choice "Check your understanding" cards.
// Authoring (in a .qmd file):
//   ::: {.bs-quiz}
//   Question text
//
//   - [ ] Wrong option
//   - [x] Correct option
//
//   ::: {.bs-quiz-why}
//   Explanation shown after answering.
//   :::
//   :::
(function () {
  var RIGHT = ["Exactly right.", "Correct.", "That's it.", "Well done."];
  var WRONG = ["Not quite.", "Not this one.", "Close, but no."];

  function build(quiz, index, total) {
    var list = quiz.querySelector("ul.task-list, ul");
    if (!list) return;
    var why = quiz.querySelector(".bs-quiz-why");
    var question = document.createElement("div");
    question.className = "bs-quiz-q";
    Array.prototype.slice.call(quiz.children).forEach(function (el) {
      if (el !== list && el !== why) question.appendChild(el);
    });

    var opts = [];
    Array.prototype.slice.call(list.children).forEach(function (li, i) {
      var box = li.querySelector("input[type=checkbox]");
      var correct = !!(box && box.checked);
      if (box) box.remove();
      var label = li.querySelector("label") || li;
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "bs-quiz-opt";
      btn.setAttribute("data-correct", correct ? "1" : "0");
      var letter = document.createElement("span");
      letter.className = "bs-quiz-letter";
      letter.textContent = String.fromCharCode(65 + i);
      var text = document.createElement("span");
      text.className = "bs-quiz-text";
      while (label.firstChild) text.appendChild(label.firstChild);
      btn.appendChild(letter);
      btn.appendChild(text);
      opts.push(btn);
    });

    var head = document.createElement("div");
    head.className = "bs-quiz-head";
    head.innerHTML = '<span class="bs-quiz-eyebrow">Check your understanding</span>' +
      '<span class="bs-quiz-count">' + (index + 1) + " of " + total + "</span>";

    var optsWrap = document.createElement("div");
    optsWrap.className = "bs-quiz-opts";
    opts.forEach(function (b) { optsWrap.appendChild(b); });

    var feedback = document.createElement("div");
    feedback.className = "bs-quiz-feedback";
    feedback.setAttribute("aria-live", "polite");
    feedback.hidden = true;
    var verdict = document.createElement("strong");
    feedback.appendChild(verdict);
    if (why) {
      why.hidden = false;
      feedback.appendChild(why);
    }

    var footer = document.createElement("div");
    footer.className = "bs-quiz-footer";
    footer.hidden = true;
    var retry = document.createElement("button");
    retry.type = "button";
    retry.className = "bs-quiz-retry";
    retry.textContent = "Try again";
    footer.appendChild(retry);
    var note = document.createElement("span");
    note.className = "bs-quiz-note";
    note.textContent = "Learn from the explanation, not just the score.";
    footer.appendChild(note);

    quiz.innerHTML = "";
    quiz.appendChild(head);
    quiz.appendChild(question);
    quiz.appendChild(optsWrap);
    quiz.appendChild(feedback);
    quiz.appendChild(footer);
    quiz.classList.add("is-ready");

    opts.forEach(function (btn) {
      btn.addEventListener("click", function () {
        if (quiz.classList.contains("is-answered")) return;
        var ok = btn.getAttribute("data-correct") === "1";
        quiz.classList.add("is-answered");
        btn.classList.add(ok ? "is-right" : "is-wrong");
        opts.forEach(function (o) {
          o.setAttribute("aria-disabled", "true");
          if (o.getAttribute("data-correct") === "1") o.classList.add("is-correct");
          else if (o !== btn) o.classList.add("is-dim");
        });
        verdict.textContent = (ok ? RIGHT : WRONG)[index % (ok ? RIGHT.length : WRONG.length)] + " ";
        feedback.className = "bs-quiz-feedback " + (ok ? "ok" : "no");
        feedback.hidden = false;
        footer.hidden = false;
        retry.hidden = ok;
        updateScore();
      });
    });
    retry.addEventListener("click", function () {
      quiz.classList.remove("is-answered");
      opts.forEach(function (o) {
        o.classList.remove("is-right", "is-wrong", "is-correct", "is-dim");
        o.removeAttribute("aria-disabled");
      });
      feedback.hidden = true;
      footer.hidden = true;
      updateScore();
    });
  }

  function updateScore() {
    var all = document.querySelectorAll(".bs-quiz.is-ready");
    var done = 0, right = 0;
    all.forEach(function (q) {
      if (q.classList.contains("is-answered")) {
        done++;
        if (q.querySelector(".bs-quiz-opt.is-right")) right++;
      }
    });
    document.querySelectorAll(".bs-quiz-score").forEach(function (el) {
      el.textContent = done === 0 ? "" : right + " of " + done + " answered correctly" + (done === all.length ? " (all done)" : "");
    });
  }

  function init() {
    var quizzes = document.querySelectorAll("main .bs-quiz");
    quizzes.forEach(function (q, i) { build(q, i, quizzes.length); });
    if (quizzes.length) {
      var score = document.createElement("p");
      score.className = "bs-quiz-score";
      var last = quizzes[quizzes.length - 1];
      last.parentNode.insertBefore(score, last.nextSibling);
    }
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
