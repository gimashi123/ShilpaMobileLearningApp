import PDFDocument from "pdfkit";

type BrailleCell = number[]; // dots 1..6
type Mapping = Record<string, BrailleCell | null | undefined>;

type QuizItem = { q: string };

type Payload = {
  title?: string;
  items?: QuizItem[];
  perPage?: number;
};

/* ---------------- BRAILLE DRAWING ---------------- */

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

  // background dots
  Object.values(positions).forEach(([px, py]) => {
    doc.fillColor("#DDDDDD").circle(px, py, r).fill();
  });

  // active dots
  (onDots ?? []).forEach((d) => {
    const p = positions[d];
    if (p) doc.fillColor("#000000").circle(p[0], p[1], r).fill();
  });

  return x + gap;
}

function drawBrailleWord(doc: any, x: number, y: number, cells: BrailleCell[]) {
  let cx = x;
  for (const cell of cells) {
    cx = drawBrailleCell(doc, cx, y, cell);
  }
}

/* ---------------- BRAILLE LOGIC (NUMBER SIGN MODE) ---------------- */

// Standard school braille number sign: ⠼ (dots 3-4-5-6)
const NUMBER_SIGN: BrailleCell = [3, 4, 5, 6];

// Digits in many school braille systems: 1–0 == a–j
// 1=a,2=b,3=c,4=d,5=e,6=f,7=g,8=h,9=i,0=j
const DIGIT_TO_CELL: Record<string, BrailleCell> = {
  "1": [1],         // a
  "2": [1, 2],      // b
  "3": [1, 4],      // c
  "4": [1, 4, 5],   // d
  "5": [1, 5],      // e
  "6": [1, 2, 4],   // f
  "7": [1, 2, 4, 5],// g
  "8": [1, 2, 5],   // h
  "9": [2, 4],      // i
  "0": [2, 4, 5],   // j
};

// Operators (commonly used in basic school braille outside Nemeth)
// You can change these if your Sri Lanka book uses different cells.
const OP_TO_CELL: Record<string, BrailleCell> = {
  "+": [3, 4, 6],       // ⠬ (often used as plus)
  "-": [3, 6],          // ⠤ or similar (basic minus)
  "×": [3, 5],          // placeholder; adjust if needed
  "x": [3, 5],          // allow 'x' as multiply
  "÷": [3, 4],          // placeholder; adjust if needed
  "/": [3, 4],          // allow '/' as divide
  "=": [2, 3, 5, 6],    // ⠶ often used for equals
  "?": [2, 6],          // ⠦ often used for question mark
};

// Convert a question string into braille cells with correct number-sign behavior
function toBrailleCellsSchoolMath(input: string, mapping: Mapping): BrailleCell[] {
  const out: BrailleCell[] = [];
  let inNumberMode = false;

  for (const ch of Array.from(input)) {
    // space
    if (ch === " ") {
      out.push(null as any); // marker for spacing
      inNumberMode = false;  // end number mode on space
      continue;
    }

    // digit
    if (DIGIT_TO_CELL[ch]) {
      if (!inNumberMode) {
        out.push(NUMBER_SIGN);
        inNumberMode = true;
      }
      out.push(DIGIT_TO_CELL[ch]);
      continue;
    }

    // operator
    if (OP_TO_CELL[ch]) {
      out.push(OP_TO_CELL[ch]);
      inNumberMode = false; // after operator, next number needs number sign again
      continue;
    }

    // fallback to your mapping (Sinhala letters etc.)
    const cell = mapping[ch];
    if (Array.isArray(cell)) {
      out.push(cell);
    } else {
      // unknown char => treat as space
      out.push(null as any);
    }

    inNumberMode = false;
  }

  // remove null markers later when drawing: we convert null->gap
  return out;
}

/* ---------------- MAIN PDF GENERATOR ---------------- */

export default function generateBraillePdf(payload: Payload, mapping: Mapping) {
  const doc = new PDFDocument({ size: "A4", margin: 40 });

  const items = payload.items ?? [];
  const perPage = Number(payload.perPage ?? 5);
  const totalPages = Math.ceil(items.length / perPage);

  for (let page = 0; page < totalPages; page++) {
    if (page > 0) doc.addPage();

    doc.fontSize(18).text(payload.title || "Quiz", { align: "center" });
    doc.moveDown(0.5);
    doc.fontSize(12).text(`Page ${page + 1} / ${totalPages}`, { align: "center" });

    let y = 120;
    const startX = 60;

    const start = page * perPage;
    const end = Math.min(start + perPage, items.length);

    for (let i = start; i < end; i++) {
      const qText = items[i]?.q ?? "";

      doc.fontSize(12).fillColor("#111111").text(`${i + 1}. ${qText}`, startX, y);
      y += 20;

      // ✅ NEW: proper number sign logic for math strings
      const cellsRaw = toBrailleCellsSchoolMath(qText, mapping);

      // draw with spacing: if null => add a gap
      let cx = startX;
      for (const cell of cellsRaw) {
        if (cell == null) {
          cx += 14; // space gap
          continue;
        }
        cx = drawBrailleCell(doc, cx, y, cell);
      }
      y += 36;

      doc.fillColor("#444444").text("Answer: ____________________", startX, y);
      y += 28;
    }
  }

  return doc;
}
