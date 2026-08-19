// EXPECT: footnote: cannot keep the label <note> on a footnote that is hidden
// EXPECT: on every step this render puts on a page. Label the text around the
// EXPECT: footnote, or render the step that reveals it.
#import "../../src/core/footnotes.typ": placeholder
#let labelled = [#footnote[a note] <note>].children.first()
#let _ = placeholder(labelled, keeps-labels: true)
