// EXPECT: rebuild: cannot reconstruct element outline with fields ("title",)
// EXPECT: containing a footnote to replace on a step that hides it. Register it
// EXPECT: with register-container(fn, positional).
#import "../../src/core/footnotes.typ": is-entry, placeholder
#import "../../src/core/walk.typ": rebuild
#let _ = rebuild(
  outline(title: [#footnote[note]]),
  child => placeholder(child),
  match: is-entry,
  subject: "a footnote to replace on a step that hides it",
)
