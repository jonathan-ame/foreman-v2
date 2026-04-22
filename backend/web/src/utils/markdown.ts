// Lightweight markdown-to-HTML converter (no dependencies).
// Supports: paragraphs, headings, bold, italic, links, inline code,
// code blocks, unordered lists, ordered lists, blockquotes, horizontal rules,
// tables (GFM-style).

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

  function parseTableRow(row: string): string[] {
    const trimmed = row.trim();
    const content = trimmed.startsWith("|") ? trimmed.slice(1) : trimmed;
    const cells = content.endsWith("|") ? content.slice(0, -1) : content;
    return cells.split("|").map((c) => inline(c.trim()));
  }

  function isSeparatorRow(row: string): boolean {
    return /^\|?\s*(:?---+:?\s*\|)+\s*:?---+:?\s*\|?\s*$/.test(row.trim());
  }

  function renderTable(startIdx: number): { html: string; nextIdx: number } {
    const headerCells = parseTableRow(lines[startIdx]);
    const thead = "<thead><tr>" + headerCells.map((c) => "<th>" + c + "</th>").join("") + "</tr></thead>";

    let rowIdx = startIdx + 1;
    if (rowIdx < lines.length && isSeparatorRow(lines[rowIdx])) {
      rowIdx++;
    }

    const bodyRows: string[] = [];
    while (rowIdx < lines.length && lines[rowIdx].trim().startsWith("|")) {
      const cells = parseTableRow(lines[rowIdx]);
      bodyRows.push("<tr>" + cells.map((c) => "<td>" + c + "</td>").join("") + "</tr>");
      rowIdx++;
    }

    const tbody = bodyRows.length > 0 ? "<tbody>" + bodyRows.join("") + "</tbody>" : "";
    return { html: "<table>" + thead + tbody + "</table>", nextIdx: rowIdx };
  }

  let i = 0;
  while (i < lines.length) {
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
      i++;
      continue;
    }
    if (inCodeBlock) {
      codeBuffer.push(line);
      i++;
      continue;
    }

    // Tables
    if (line.trim().startsWith("|") && i + 1 < lines.length && isSeparatorRow(lines[i + 1])) {
      closeList();
      const { html, nextIdx } = renderTable(i);
      out.push(html);
      i = nextIdx;
      continue;
    }

    // Headings
    const hMatch = line.match(/^(#{1,6})\s+(.+)/);
    if (hMatch) {
      closeList();
      const level = hMatch[1].length;
      out.push(`<h${level}>${inline(hMatch[2])}</h${level}>`);
      i++;
      continue;
    }

    // Horizontal rule
    if (/^---+$/.test(line.trim())) {
      closeList();
      out.push("<hr />");
      i++;
      continue;
    }

    // Blockquote
    if (line.startsWith("> ")) {
      closeList();
      out.push("<blockquote>" + inline(line.slice(2)) + "</blockquote>");
      i++;
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
      i++;
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
      i++;
      continue;
    }

    // Empty line
    if (line.trim() === "") {
      closeList();
      i++;
      continue;
    }

    // Paragraph
    closeList();
    out.push("<p>" + inline(line) + "</p>");
    i++;
  }

  closeList();
  if (inCodeBlock) {
    out.push("<pre><code>" + codeBuffer.join("\n") + "</code></pre>");
  }

  return out.join("\n");
}
