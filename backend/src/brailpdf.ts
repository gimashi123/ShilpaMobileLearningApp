import PDFDocument from "pdfkit";

type BrailleCell = number[]; // e.g. [1,4,5]
type Mapping = Record<string, BrailleCell | null | undefined>;

type QuizItem = { q: string };
type Payload = { title?: string; items?: QuizItem[] };

function drawBrailleCell(
  doc: any,
  x: number,
  y: number,
  onDots: BrailleCell | null | undefined,
  opts: { radius?: number; dx?: number; dy?: number; gap?: number } = {}
) {
  const r = opts.radius ?? 2.2;
  const dx = opts.dx ?? 10;
  const dy = opts.dy ?? 10;
  const gap = opts.gap ?? 22;

  const positions: Record<number, [number, number]> = {
    1: [x, y],
    2: [x, y + dy],
    3: [x, y + 2 * dy],
    4: [x + dx, y],
    5: [x + dx, y + dy],
    6: [x + dx, y + 2 * dy],
  };

  // faint background dots
  Object.values(positions).forEach(([px, py]) => {
    doc.save();
    doc.fillColor("#DDDDDD");
    doc.circle(px, py, r).fill();
    doc.restore();
  });

  // active dots
  (onDots ?? []).forEach((d) => {
    const pos = positions[d];
    if (!pos) return;
    doc.fillColor("#000000");
    doc.circle(pos[0], pos[1], r).fill();
  });

  return x + gap;
}

function drawBrailleWord(doc: any, x: number, y: number, cells: BrailleCell[]) {
  let cx = x;
  for (const cell of cells) {
    cx = drawBrailleCell(doc, cx, y, cell);
  }
}

export default function generateBraillePdf(payload: Payload, mapping: Mapping) {
  const doc = new PDFDocument({ size: "A4", margin: 40 });

  doc.fontSize(18).text(payload.title || "Quiz", { align: "center" });
  doc.moveDown();

  const startX = 60;
  let y = 110;

  (payload.items ?? []).forEach((it, idx) => {
    doc.fontSize(12).fillColor("#111111").text(`${idx + 1}. ${it.q}`, startX, y);
    y += 22;

    const cells: BrailleCell[] = Array.from(it.q || "")
      .map((ch) => mapping[ch])
      .filter((v): v is BrailleCell => Array.isArray(v));

    if (cells.length) {
      drawBrailleWord(doc, startX, y, cells);
      y += 40;
    } else {
      y += 18;
    }

    doc.fillColor("#444444").text("Answer: ____________________", startX, y);
    y += 28;

    if (y > 740) {
      doc.addPage();
      y = 80;
    }
  });

  return doc;
}
