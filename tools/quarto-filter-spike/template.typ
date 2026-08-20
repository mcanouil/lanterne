// The Pandoc template the spike renders through.
//
// Quarto's own typst-show partial would be the equivalent in a real extension.
// This is deliberately smaller: the spike is about what the filter emits, not
// about the document furniture Quarto wraps it in.
//
// Nothing here may name a template variable, even inside a comment. Pandoc
// interpolates the whole file, comments included, so a comment that mentions the
// body placeholder has the whole document substituted into it and the imports
// below end up after the deck they configure. That cost an hour once.
#import "/lib.typ" as lanterne
#import "/lib.typ": *

#show: deck.with(slide-level: 2)

$body$
