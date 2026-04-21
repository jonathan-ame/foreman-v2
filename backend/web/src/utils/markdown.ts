// Lightweight markdown-to-HTML converter (no dependencies).
// Supports: paragraphs, headings, bold, italic, links, inline code,
// code blocks, unordered lists, ordered lists, blockquotes, horizontal rules.

export function renderMarkdown(md: string): string {
  const lines = md.split("\n");
  const out: string[] = [];
  let inList = false;
  let listOrdered = false;
  let inCodeBlock = false;
  let codeBuffer: string[] = [];

  function closeList() {
    if (inList) {
      out.push(listOrdered ? "</ol>" : "</ul>");
      inList = false;
    }
  }

  function inline(text: string): string {
    return text
      .replace(/`([^`]+)`/g, "<code>$1</code>")
      .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
      .replace(/(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/g, "<em>$1</em>")
      .replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2">$1</a>');
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Code blocks
    if (line.startsWith("```")) {
      if (inCodeBlock) {
        out.push("<pre><code>" + codeBuffer.join("\n") + "</code></pre>");
        codeBuffer = [];
        inCodeBlock = false;
      } else {
        closeList();
        inCodeBlock = true;
      }
      continue;
    }
    if (inCodeBlock) {
      codeBuffer.push(line);
      continue;
    }

    // Headings
    const hMatch = line.match(/^(#{1,6})\s+(.+)/);
    if (hMatch) {
      closeList();
      const level = hMatch[1].length;
      out.push(`<h${level}>${inline(hMatch[2])}</h${level}>`);
      continue;
    }

    // Horizontal rule
    if (/^---+$/.test(line.trim())) {
      closeList();
      out.push("<hr />");
      continue;
    }

    // Blockquote
    if (line.startsWith("> ")) {
      closeList();
      out.push("<blockquote>" + inline(line.slice(2)) + "</blockquote>");
      continue;
    }

    // Unordered list
    const ulMatch = line.match(/^[-*]\s+(.+)/);
    if (ulMatch) {
      if (!inList || listOrdered) {
        closeList();
        inList = true;
        listOrdered = false;
        out.push("<ul>");
      }
      out.push("<li>" + inline(ulMatch[1]) + "</li>");
      continue;
    }

    // Ordered list
    const olMatch = line.match(/^\d+\.\s+(.+)/);
    if (olMatch) {
      if (!inList || !listOrdered) {
        closeList();
        inList = true;
        listOrdered = true;
        out.push("<ol>");
      }
      out.push("<li>" + inline(olMatch[1]) + "</li>");
      continue;
    }

    // Empty line
    if (line.trim() === "") {
      closeList();
      continue;
    }

    // Paragraph
    closeList();
    out.push("<p>" + inline(line) + "</p>");
  }

  closeList();
  if (inCodeBlock) {
    out.push("<pre><code>" + codeBuffer.join("\n") + "</code></pre>");
  }

  return out.join("\n");
}
