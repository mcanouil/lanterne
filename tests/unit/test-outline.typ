// What a deck contributes to the outline and to the PDF bookmarks.
//
// A slide's title is the heading the author wrote, and a stepped slide emits
// its body once per step, so the title is emitted once per step too. Nothing
// structural can see the consequence: the records are identical whatever the
// outline ends up listing, so these assertions read the rendered document.

#import "/src/core/slides.typ": appendix, slide, slide-options, slides
#import "/src/core/steps.typ": pause
#import "/src/render/deck.typ": deck

#let headings-of(title) = query(heading).filter(it => it.body == title)

// A section slide, then a stepped content slide.
#deck([
  = Section
  == Content
  a #pause b
])

#context {
  // The stepped slide renders two pages, and its title is listed once.
  assert.eq(headings-of([Content]).len(), 2)
  assert.eq(headings-of([Content]).filter(it => it.outlined).len(), 1)
  assert.eq(headings-of([Content]).first().outlined, true)

  // A section slide is a bookmark and a content slide is not, per
  // specification 4.7.
  assert.eq(headings-of([Section]).first().bookmarked, auto)
  assert.eq(headings-of([Content]).first().bookmarked, false)

  // The repeated step contributes neither an entry nor a bookmark.
  assert.eq(headings-of([Content]).last().outlined, false)
  assert.eq(headings-of([Content]).last().bookmarked, false)
}

// An in-slide heading, deeper than the slide level, follows the slide it sits
// on: a content slide contributes no bookmarks at all.
#deck([
  == Carrier
  === Inside
])

#context {
  assert.eq(headings-of([Inside]).first().bookmarked, false)
}

// The appendix marker is a switch: every slide after it is an appendix slide,
// and the marker itself opens nothing.
#let after-appendix = slides([
  == Before
  a

  #appendix

  == First extra
  b

  == Second extra
  c
])

#assert.eq(after-appendix.len(), 3)
#assert.eq(after-appendix.map(record => record.attrs.appendix), (false, true, true))
#assert.eq(after-appendix.map(record => record.title), ([Before], [First extra], [Second extra]))

// The marker sets the option, so the machine surface receives an ordinary slide
// option, and a slide that states one itself wins over the switch.
#let overridden = slides([
  #appendix

  == Extra
  #slide-options(appendix: false)
  b
])

#assert.eq(overridden.map(record => record.attrs.appendix), (false,))

// An appendix slide is excluded from the outline and is no bookmark, per
// specification 4.7, while the slides before it are unaffected.
#deck([
  == Ordinary
  a

  #appendix

  == Extra
  b
])

#context {
  assert.eq(headings-of([Ordinary]).first().outlined, true)
  assert.eq(headings-of([Extra]).first().outlined, false)
  assert.eq(headings-of([Extra]).first().bookmarked, false)
}

// An explicit slide written after the marker is an appendix slide as much as
// one a heading opened, so the switch reaches the record it builds.
#let with-explicit = slides([
  #appendix

  #slide(title: [Written out])[body]
])

#assert.eq(with-explicit.map(record => record.attrs.appendix), (true,))

// A slide marked on its own, with no switch anywhere, is excluded at render
// time and not merely in its record.
#deck([
  == Kept
  a

  == Dropped
  #slide-options(appendix: true)
  b
])

#context {
  assert.eq(headings-of([Kept]).first().outlined, true)
  assert.eq(headings-of([Dropped]).first().outlined, false)
  assert.eq(headings-of([Dropped]).first().bookmarked, false)
}

// A section slide inside the appendix is excluded as well, so the appendix
// contributes no bookmark at all.
#deck([
  == Body slide
  a

  #appendix

  = Extra section
  == Extra content
  b
])

#context {
  assert.eq(headings-of([Extra section]).first().outlined, false)
  assert.eq(headings-of([Extra section]).first().bookmarked, false)
  assert.eq(headings-of([Extra content]).first().outlined, false)
}

// Every heading on a section slide's page is a bookmark, the title and anything
// written under it alike, because the rule is per page rather than per level.
// A divider carrying its own sub-heading is unusual, and this pins what happens
// rather than claiming it cannot.
#deck([
  = Divider
  === Under the divider
])

#context {
  assert.eq(headings-of([Under the divider]).first().bookmarked, auto)
}

// An author who suppresses outline entries deck-wide keeps that: the page rule
// writes only what it has to suppress, so it never turns an entry back on.
#[
  #set heading(outlined: false)
  #deck([
    == Quiet
    a
  ])
]

#context {
  assert.eq(headings-of([Quiet]).first().outlined, false)
}
