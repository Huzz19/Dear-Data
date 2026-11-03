import java.util.Collections;

// Reads workouts.csv (columns: Type, Length, Date), sorts by date,
// and draws one shape per workout in a grid, read left to right, top to bottom.
// Chest = circle, Arms = square, Legs = triangle
// Shape size scales with workout length (minutes).
// Hover over a shape to see its exact length.

ArrayList<Workout> workouts = new ArrayList<Workout>();
int skipped = 0;

float minTime = Float.MAX_VALUE;
float maxTime = 0;
float minSize, maxSize;

// Grid layout
int cols = 6;
int rows;
float cellW, cellH;
float topMargin = 110;
float labelH = 18;  // room under each shape for its date

String[] months = {"jan", "feb", "mar", "apr", "may", "jun",
                   "jul", "aug", "sep", "oct", "nov", "dec"};

class Workout implements Comparable<Workout> {
  String kind;
  float minutes;
  int month, day;
  String label;

  Workout(String kind, float minutes, int month, int day, String label) {
    this.kind = kind;
    this.minutes = minutes;
    this.month = month;
    this.day = day;
    this.label = label;
  }

  public int compareTo(Workout other) {
    return (month * 100 + day) - (other.month * 100 + other.day);
  }
}

void setup() {
  size(800, 720);
  textAlign(CENTER);
  textSize(16);
  rectMode(CENTER);

  // Load without header mode so a BOM on the first header can't break column lookup
  Table table = loadTable("workouts.csv", "csv");

  // Row 0 is the header row, so start at 1
  for (int i = 1; i < table.getRowCount(); i++) {
    TableRow row = table.getRow(i);

    String kind = row.getString(0);
    String lengthText = row.getString(1);
    String dateText = row.getString(2);
    if (kind == null || lengthText == null || dateText == null) {
      skipped++;
      continue;
    }

    kind = kind.replace("\uFEFF", "").trim().toLowerCase();
    dateText = dateText.trim();

    // "43m" becomes 43
    String digits = lengthText.replaceAll("[^0-9.]", "");
    float t = 0;
    if (digits.length() > 0) {
      try {
        t = Float.parseFloat(digits);
      } catch (NumberFormatException e) {
        t = 0;
      }
    }

    int[] md = parseDate(dateText);
    boolean validKind = kind.equals("chest") || kind.equals("arms") || kind.equals("legs");

    if (validKind && t > 0 && md != null) {
      workouts.add(new Workout(kind, t, md[0], md[1], dateText));
      minTime = min(minTime, t);
      maxTime = max(maxTime, t);
    } else {
      skipped++;
    }
  }

  // Chronological order (stable, so same-day workouts keep file order)
  Collections.sort(workouts);

  // Size the grid cells, then size shapes to fit inside them so nothing overlaps
  rows = max(1, ceil(workouts.size() / (float) cols));
  cellW = width / (float) cols;
  cellH = (height - topMargin - 10) / rows;
  maxSize = min(cellW, cellH - labelH) - 12;
  minSize = maxSize * 0.35;

  noLoop();  // redraws only when the mouse moves (see mouseMoved)
}

// Redraw whenever the mouse moves so hover effects update
void mouseMoved() {
  redraw();
}

// Parses "05-Sep" into {month (1-12), day}. Returns null if it can't.
int[] parseDate(String s) {
  String[] parts = s.split("-");
  if (parts.length != 2) return null;

  int day;
  try {
    day = Integer.parseInt(parts[0].trim());
  } catch (NumberFormatException e) {
    return null;
  }

  String m = parts[1].trim().toLowerCase();
  if (m.length() < 3) return null;
  m = m.substring(0, 3);

  for (int i = 0; i < 12; i++) {
    if (months[i].equals(m)) {
      return new int[] {i + 1, day};
    }
  }
  return null;
}

void draw() {
  background(240);

  int hovered = -1;

  for (int i = 0; i < workouts.size(); i++) {
    Workout w = workouts.get(i);
    int col = i % cols;
    int row = i / cols;

    float cx = col * cellW + cellW / 2;
    float cellTop = topMargin + row * cellH;
    float cy = cellTop + (cellH - labelH) / 2;
    float s = sizeFor(w.minutes);

    boolean over = isOver(w.kind, cx, cy, s, mouseX, mouseY);
    if (over) hovered = i;

    drawShape(w.kind, cx, cy, s, over);

    // Date label under the shape
    fill(90);
    textSize(12);
    text(w.label, cx, cellTop + cellH - 4);
  }

  // Header
  fill(0);
  textSize(16);
  String msg = workouts.size() + " workouts loaded";
  if (skipped > 0) {
    msg += " (" + skipped + " rows skipped)";
  }
  text(msg, width / 2, 30);
  if (workouts.size() > 0) {
    text("Size = length (" + nf(minTime, 0, 0) + " to " + nf(maxTime, 0, 0) + " min)", width / 2, 55);
  }

  drawLegend();

  // Tooltip is drawn last so it sits on top of everything
  if (hovered >= 0) {
    cursor(HAND);
    drawTooltip(workouts.get(hovered));
  } else {
    cursor(ARROW);
  }
}

// Maps a workout length to a shape size
float sizeFor(float t) {
  if (maxTime == minTime) {
    return (minSize + maxSize) / 2;  // all workouts same length
  }
  return map(t, minTime, maxTime, minSize, maxSize);
}

// Is the point (px, py) inside the shape centered at (x, y) with size s?
boolean isOver(String kind, float x, float y, float s, float px, float py) {
  float dx = px - x;
  float dy = py - y;

  if (kind.equals("chest")) {
    return dx * dx + dy * dy <= (s / 2) * (s / 2);
  } else if (kind.equals("arms")) {
    return abs(dx) <= s / 2 && abs(dy) <= s / 2;
  } else if (kind.equals("legs")) {
    // Triangle: apex at the top, widening linearly to the base
    float top = y - s / 2;
    if (py < top || py > y + s / 2) return false;
    float halfWidth = ((py - top) / s) * (s / 2);
    return abs(dx) <= halfWidth;
  }
  return false;
}

String formatMinutes(float m) {
  if (m == floor(m)) {
    return str(int(m));
  }
  return nf(m, 0, 1);
}

String capitalize(String s) {
  return s.substring(0, 1).toUpperCase() + s.substring(1);
}

void drawTooltip(Workout w) {
  String line1 = formatMinutes(w.minutes) + " min";
  String line2 = capitalize(w.kind) + " - " + w.label;

  textSize(16);
  float w1 = textWidth(line1);
  textSize(12);
  float w2 = textWidth(line2);

  float boxW = max(w1, w2) + 20;
  float boxH = 46;

  float bx = mouseX + 14;
  float by = mouseY + 14;
  if (bx + boxW > width) bx = mouseX - 14 - boxW;
  if (by + boxH > height) by = mouseY - 14 - boxH;

  rectMode(CORNER);
  stroke(60);
  strokeWeight(1);
  fill(255, 245);
  rect(bx, by, boxW, boxH, 6);
  rectMode(CENTER);

  noStroke();
  fill(0);
  textAlign(LEFT, TOP);
  textSize(16);
  text(line1, bx + 10, by + 6);
  fill(90);
  textSize(12);
  text(line2, bx + 10, by + 28);

  // Restore defaults used elsewhere
  textAlign(CENTER, BASELINE);
  textSize(16);
}

void drawLegend() {
  float y = 85;
  float spacing = 140;
  float startX = width / 2 - spacing;

  drawShape("chest", startX, y, 20, false);
  drawShape("arms", startX + spacing, y, 20, false);
  drawShape("legs", startX + spacing * 2, y, 20, false);

  fill(0);
  textAlign(LEFT, CENTER);
  textSize(14);
  text("Chest", startX + 18, y);
  text("Arms", startX + spacing + 18, y);
  text("Legs", startX + spacing * 2 + 18, y);
  textAlign(CENTER, BASELINE);
  textSize(16);
}

void drawShape(String kind, float x, float y, float s, boolean highlight) {
  if (highlight) {
    stroke(0);
    strokeWeight(2);
  } else {
    noStroke();
  }

  if (kind.equals("chest")) {
    fill(230, 80, 80, 200);
    ellipse(x, y, s, s);
  } else if (kind.equals("arms")) {
    fill(80, 140, 230, 200);
    rect(x, y, s, s);
  } else if (kind.equals("legs")) {
    fill(90, 190, 110, 200);
    triangle(x, y - s / 2, x - s / 2, y + s / 2, x + s / 2, y + s / 2);
  }
  noStroke();
}
