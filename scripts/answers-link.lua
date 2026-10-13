-- Website only: point readers to the page that collects every answer.
if not FORMAT:match("html") then return {} end

function Para(el)
  local txt = pandoc.utils.stringify(el)
  if txt:match("^Answers are provided below%.") then
    el.content:extend({ pandoc.Space(), pandoc.Str("You"), pandoc.Space(), pandoc.Str("can"), pandoc.Space(),
      pandoc.Str("also"), pandoc.Space(), pandoc.Str("find"), pandoc.Space(), pandoc.Str("every"), pandoc.Space(),
      pandoc.Str("answer"), pandoc.Space(), pandoc.Str("on"), pandoc.Space(), pandoc.Str("the"), pandoc.Space(),
      pandoc.Link("Answers to Exercises", "answers.html"), pandoc.Space(), pandoc.Str("page.") })
    return el
  end
end
