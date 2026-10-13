-- PDF-only tweaks: styled boxes for formulas, examples and answers,
-- and links that work outside the website.
if not FORMAT:match("latex") then return {} end

local SITE = "https://jagelves.github.io/BusinessStats/"

local function latex(s) return pandoc.RawBlock("latex", s) end

local function pull_title(blocks, fallback)
  local first = blocks[1]
  if first and first.t == "Para" and first.content[1] and first.content[1].t == "Strong" then
    local title = pandoc.utils.stringify(first.content[1]):gsub(":%s*$", "")
    local rest = pandoc.List()
    for i = 2, #first.content do rest:insert(first.content[i]) end
    while rest[1] and (rest[1].t == "Space" or rest[1].t == "SoftBreak") do rest:remove(1) end
    if #rest > 0 then blocks[1] = pandoc.Para(rest) else blocks:remove(1) end
    return title
  end
  return fallback
end

local function escape(s) return (s:gsub("([%%&#_{}%$])", "\\%1")) end

-- Tables inside formula/example boxes: plain tabular (a longtable inside a
-- breakable box forces a page break right after it).
local function cell_latex(blocks)
  local out = pandoc.write(pandoc.Pandoc(blocks), "latex")
  return (out:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\n\n+", " \\newline "))
end

local function table_to_tabular(tbl)
  local st = pandoc.utils.to_simple_table(tbl)
  local align = { AlignLeft = "l", AlignRight = "r", AlignCenter = "c", AlignDefault = "c" }
  local spec = {}
  for _, a in ipairs(st.aligns) do table.insert(spec, align[a] or "c") end
  local lines = { "\\begin{center}", "\\begin{tabular}{" .. table.concat(spec) .. "}", "\\toprule" }
  local has_header = false
  for _, c in ipairs(st.headers) do if #c > 0 then has_header = true end end
  if has_header then
    local h = {}
    for _, c in ipairs(st.headers) do table.insert(h, cell_latex(c)) end
    table.insert(lines, table.concat(h, " & ") .. " \\\\")
    table.insert(lines, "\\midrule")
  end
  for _, row in ipairs(st.rows) do
    local r = {}
    for _, c in ipairs(row) do table.insert(r, cell_latex(c)) end
    table.insert(lines, table.concat(r, " & ") .. " \\\\")
  end
  table.insert(lines, "\\bottomrule")
  table.insert(lines, "\\end{tabular}")
  table.insert(lines, "\\end{center}")
  return pandoc.RawBlock("latex", table.concat(lines, "\n"))
end

-- Short tables everywhere become a plain tabular so they never trigger an
-- early page break inside an answer or example box.
function Table(tbl)
  local nrows = 0
  for _, body in ipairs(tbl.bodies) do nrows = nrows + #body.body end
  local has_caption = #pandoc.utils.stringify(tbl.caption.long or {}) > 0
  if nrows <= 20 and not has_caption then return table_to_tabular(tbl) end
end

function Div(el)
  local env, fallback
  if el.classes:includes("callout-formula") then env, fallback = "bsformula", "Formula"
  elseif el.classes:includes("callout-example") then env, fallback = "bsexample", "Example" end
  if env then
    el.content = el.content:walk({ Table = table_to_tabular })
    local title = pull_title(el.content, fallback)
    local out = pandoc.List({ latex("\\begin{" .. env .. "}[" .. escape(title) .. "]") })
    out:extend(el.content)
    out:insert(latex("\\end{" .. env .. "}"))
    return out
  end
end

-- <details><summary>Answer</summary> ... </details>  ->  an "Answer" box
local function html_text(b)
  if b.t == "RawBlock" and b.format == "html" then return b.text end
  if b.t == "Para" or b.t == "Plain" then
    local parts = {}
    for _, i in ipairs(b.content) do
      if i.t == "RawInline" and i.format == "html" then table.insert(parts, i.text)
      else table.insert(parts, pandoc.utils.stringify(i)) end
    end
    local s = table.concat(parts)
    if s:match("^%s*<") then return s end
  end
  return nil
end

local function summary_of(b)
  local t = html_text(b)
  if t then
    local s = t:match("^%s*<summary>%s*(.-)%s*</summary>%s*$")
    if s then return s end
  end
  return nil
end

function Blocks(blocks)
  local out = pandoc.List()
  local i = 1
  while i <= #blocks do
    local b = blocks[i]
    local t = html_text(b)
    if t and t:match("^%s*<details>%s*$") then
      local title = "Answer"
      local nxt = blocks[i + 1]
      local s = nxt and summary_of(nxt)
      if s then title = s; i = i + 1
      elseif nxt and html_text(nxt) and html_text(nxt):match("^%s*<summary>%s*$") then
        -- pandoc splits <summary>Answer</summary> into three blocks
        local mid, close = blocks[i + 2], blocks[i + 3]
        if mid and close and html_text(close) and html_text(close):match("^%s*</summary>%s*$") then
          title = pandoc.utils.stringify(mid)
          i = i + 3
        end
      end
      if title:lower():match("video") then
        -- videos cannot play in a PDF: point to the online chapter instead
        local j = i + 1
        while j <= #blocks and not (html_text(blocks[j]) or ""):match("^%s*</details>%s*$") do j = j + 1 end
        i = j
        local page = SITE .. (pandoc.path.filename(quarto.doc.input_file):gsub("%.qmd$", ".html"):gsub(" ", "%%20"))
        out:insert(pandoc.Para({ pandoc.Emph({ pandoc.Str("Video walkthrough:"), pandoc.Space(),
          pandoc.Link("watch it in the online version of this chapter", page) }) }))
      else
        out:insert(latex("\\begin{bsanswer}[" .. escape(title) .. "]"))
      end
    elseif t and t:match("^%s*</details>%s*$") then
      out:insert(latex("\\end{bsanswer}"))
    elseif summary_of(b) then
      -- stray summary line: drop it
    else
      out:insert(b)
    end
    i = i + 1
  end
  return out
end

local function absolute(target)
  if target:match("^%a[%w+.-]*:") or target:match("^#") or target == "" then return target end
  return SITE .. target:gsub("^%./", ""):gsub(" ", "%%20")
end

-- "Answers are provided below." -> the answers now live at the end of the PDF
function Para(el)
  local txt = pandoc.utils.stringify(el)
  if txt:match("^Answers are provided below%.") then
    local rest = txt:gsub("^Answers are provided below%.%s*", "")
    local inl = pandoc.List({ pandoc.Str("Answers"), pandoc.Space(), pandoc.Str("are"), pandoc.Space(),
      pandoc.Str("in"), pandoc.Space(), pandoc.Str("the"), pandoc.Space(),
      pandoc.Link("Answers to Exercises", "#answers"), pandoc.Space(),
      pandoc.Str("at"), pandoc.Space(), pandoc.Str("the"), pandoc.Space(), pandoc.Str("end"), pandoc.Space(),
      pandoc.Str("of"), pandoc.Space(), pandoc.Str("the"), pandoc.Space(), pandoc.Str("book.") })
    if rest ~= "" then inl:insert(pandoc.Space()); inl:extend(pandoc.read(rest, "markdown").blocks[1].content) end
    return pandoc.Para(inl)
  end
end

-- gt writes percentages like "0.0659%" unescaped in its LaTeX tables, and a
-- bare % starts a LaTeX comment (it swallowed the rest of the row). Escape it.
function RawBlock(el)
  if el.format == "latex" and el.text:match("\\begin{tabular") then
    el.text = el.text:gsub("(%d)%%", "%1\\%%")
    return el
  end
end

function Header(el)
  if el.level == 2 and pandoc.utils.stringify(el):match("Cheat Sheet") then
    -- keep the heading with its (tall) cheat-sheet image
    return { latex("\\Needspace{7.4in}"), el }
  end
end

function Link(el)
  el.target = absolute(el.target)
  if el.classes:includes("btn") then
    local text = pandoc.utils.stringify(el.content):gsub("^%s+", "")
    if text == "" then text = "Download" end
    return pandoc.RawInline("latex", "\\bsdownload{" .. el.target:gsub("%%", "\\%%") .. "}{" .. escape(text) .. "}")
  end
  return el
end

-- Move every answer box to an answer key at the end of the book.
-- In the text, each question gets a small "Answer on page N" link instead.
local function is_answer_start(b)
  return b.t == "RawBlock" and b.format == "latex" and b.text:match("^\\begin{bsanswer}") ~= nil
end
local function is_answer_end(b)
  return b.t == "RawBlock" and b.format == "latex" and b.text:match("^\\end{bsanswer}") ~= nil
end

function Pandoc(doc)
  -- the online "Answers to Exercises" page is replaced by the PDF's own key
  for k, b in ipairs(doc.blocks) do
    if b.t == "Header" and b.level == 1 and b.identifier == "sec-answers-page" then
      local keep = pandoc.List()
      for m = 1, k - 1 do keep:insert(doc.blocks[m]) end
      doc.blocks = keep
      break
    end
  end
  local answers = {}          -- { {chapter=, chapnum=, label=, id=, blocks=} }
  local ctx = { chapter = nil, chapnum = 0, exercise = nil, q = nil }
  local count = 0

  local process
  process = function(blocks)
    local out = pandoc.List()
    local i = 1
    while i <= #blocks do
      local b = blocks[i]
      if b.t == "Header" and b.level == 1 then
        ctx.chapter = pandoc.utils.stringify(b.content)
        if not b.classes:includes("unnumbered") then ctx.chapnum = ctx.chapnum + 1 end
        ctx.exercise, ctx.q = nil, nil
        out:insert(b)
      elseif b.t == "Header" and pandoc.utils.stringify(b.content):match("^Exercise") then
        ctx.exercise, ctx.q = pandoc.utils.stringify(b.content), nil
        out:insert(b)
      elseif b.t == "OrderedList" then
        local start = b.listAttributes.start or 1
        for k, item in ipairs(b.content) do
          ctx.q = start + k - 1
          b.content[k] = process(item)
        end
        out:insert(b)
      elseif is_answer_start(b) then
        local body = pandoc.List()
        local j = i + 1
        while j <= #blocks and not is_answer_end(blocks[j]) do body:insert(blocks[j]); j = j + 1 end
        i = j
        count = count + 1
        local id = "bsans" .. count
        local label = ctx.exercise or "Exercise"
        if ctx.q then label = label .. ", question " .. ctx.q end
        table.insert(answers, { chapter = ctx.chapter, chapnum = ctx.chapnum, label = label, id = id, blocks = body })
        out:insert(pandoc.RawBlock("latex", "\\bsanswerref{" .. id .. "}"))
      else
        out:insert(b)
      end
      i = i + 1
    end
    return out
  end

  doc.blocks = process(doc.blocks)
  if #answers == 0 then return doc end

  local key = pandoc.List()
  key:insert(pandoc.RawBlock("latex", "\\bsanswerkeystart"))
  local current = nil
  for _, a in ipairs(answers) do
    if a.chapter ~= current then
      current = a.chapter
      key:insert(pandoc.RawBlock("latex", "\\bsanswerchapter{" .. a.chapnum .. "}{" .. escape(a.chapter) .. "}"))
    end
    key:insert(pandoc.RawBlock("latex", "\\begin{bsanswerkey}{" .. a.id .. "}{" .. escape(a.label) .. "}"))
    key:extend(a.blocks)
    key:insert(pandoc.RawBlock("latex", "\\end{bsanswerkey}"))
  end
  doc.blocks:extend(key)
  return doc
end
