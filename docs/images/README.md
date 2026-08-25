# Diagram sources

`container-view.mmd` is the source for the container diagram in [../architecture.md](../architecture.md). After editing it, regenerate the SVG:

```bash
npx @mermaid-js/mermaid-cli@11.16.0 -i docs/images/container-view.mmd -o docs/images/container-view.svg -c docs/images/mermaid-config.json -b white
ruby -i -pe 'gsub(/<text(?![^>]*xml:space)/, %q{<text xml:space="preserve"})' docs/images/container-view.svg
printf '\n' >> docs/images/container-view.svg
```

Run it from the repository root. The version is pinned because a later major restyles the output, and the two post-processing steps exist because mermaid's defaults produce an SVG that only a full browser renders correctly:

- **`htmlLabels: false`** (in `mermaid-config.json`) makes mermaid emit `<text>` elements instead of wrapping every label in a `<foreignObject>`. A renderer that ignores `<foreignObject>` draws the boxes and arrows and none of the words — librsvg does exactly that, and GitHub's markdown pipeline is the reason it matters here.
- **`xml:space="preserve"`** keeps the spaces between words. Mermaid splits a label across one `<tspan>` per word with the space at the start of each, and without that attribute a renderer trims it, so "TRA support user" comes out as "TRAsupportuser".
