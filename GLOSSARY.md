# Glossary

Short identifiers used across the source tree.
Consult this file before introducing a new abbreviation, and add an entry when you do.

## Domain vocabulary

| Term | Meaning |
| --- | --- |
| deck | The whole presentation, and the show rule entry point that builds it. |
| slide | One logical slide, which may render as several pages. |
| step | One overlay state of a slide; a slide with N steps renders N pages. |
| subslide | Synonym for step, used only when quoting other packages. |
| marker | An inert `metadata` element carrying a reserved tag, found by the traversal. |
| pause | The marker kind that cuts a slide body into successive steps. |
| handout | Render mode collapsing each slide to its final step. |
| chrome | Header, footer, progress indicator, slide number and logo. |
| token | One named theme value, such as `bg` or `font-heading`. |
| slot | A theme supplied renderer for a composite chrome piece. |
| layout | A validated dictionary describing regions and grid geometry. |
| region | A named area of a slide, such as header, body or footer. |
| cell | A named position within a layout grid. |

## Short identifiers

| Identifier | Meaning |
| --- | --- |
| `fn` | An element function, as returned by `content.func()`. |
| `ctx` | Resolved rendering context passed down the pipeline. |
| `lo`, `hi` | Lower and upper bounds of a range. |
| `reg` | The container registry dictionary. |
| `seg` | One segment produced by the splitter. |
| `idx` | A zero-based index. |
| `spec` | A validated dictionary describing a layout or a theme. |

## Naming rules

Public functions are kebab-case with a family prefix: `theme-*`, `layout-*`, `emit-*`.
Private helpers are `_` prefixed and never exported.
British spelling is used throughout, including `colour` in any user-facing name.
