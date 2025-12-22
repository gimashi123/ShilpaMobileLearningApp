function rand(min: number, max: number) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

export function generateQuestions(operation: string, count = 10) {
  const qs = [];
  for (let i = 0; i < count; i++) {
    let a, b, correctAnswer;

    if (operation === "ADD") {
      a = rand(0, 20); b = rand(0, 20);
      correctAnswer = a + b;
    } else if (operation === "SUB") {
      a = rand(0, 20); b = rand(0, 20);
      if (b > a) [a, b] = [b, a];
      correctAnswer = a - b;
    } else if (operation === "MUL") {
      a = rand(0, 12); b = rand(0, 12);
      correctAnswer = a * b;
    } else if (operation === "DIV") {
      b = rand(1, 12);
      const ans = rand(0, 12);
      a = b * ans;
      correctAnswer = ans; // because a/b = ans
    } else {
      throw new Error("Invalid operation");
    }

    qs.push({ qIndex: i, a, b, correctAnswer });
  }

  // Shuffle question order
  for (let i = qs.length - 1; i > 0; i--) {
    const j = rand(0, i);
    [qs[i], qs[j]] = [qs[j], qs[i]];
  }

  // Re-index after shuffle
  return qs.map((q, idx) => ({ ...q, qIndex: idx }));
}
