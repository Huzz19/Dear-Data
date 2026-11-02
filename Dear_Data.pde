// Type "Chest", "Arms" or "Legs" and press Enter to add a shape.
// Chest = circle, Arms = square, Legs = triangle

String typed = "";
String message = "Type Chest, Arms or Legs and press Enter";
ArrayList<String> kinds = new ArrayList<String>();
ArrayList<PVector> positions = new ArrayList<PVector>();

void setup() {
  size(600, 600);
  textAlign(CENTER);
  textSize(16);
  rectMode(CENTER);
}

void draw() {
  background(240);

  // Draw all shapes created so far
  for (int i = 0; i < kinds.size(); i++) {
    drawShape(kinds.get(i), positions.get(i).x, positions.get(i).y);
  }

  // Draw the text prompt
  fill(0);
  text(message, width / 2, 30);
  text("> " + typed, width / 2, 55);
}

void keyPressed() {
  if (key == ENTER || key == RETURN) {
    handleInput(typed.trim().toLowerCase());
    typed = "";
  } else if (key == BACKSPACE) {
    if (typed.length() > 0) {
      typed = typed.substring(0, typed.length() - 1);
    }
  } else if (key != CODED) {
    typed += key;
  }
}

void handleInput(String input) {
  if (input.equals("chest") || input.equals("arms") || input.equals("legs")) {
    kinds.add(input);
    positions.add(new PVector(random(60, width - 60), random(100, height - 60)));
    message = "Added a shape for: " + input;
  } else {
    message = "Unknown input. Please type Chest, Arms or Legs";
  }
}

void drawShape(String kind, float x, float y) {
  float s = 80;
  noStroke();

  if (kind.equals("chest")) {
    fill(230, 80, 80);
    ellipse(x, y, s, s);  // circle
  } else if (kind.equals("arms")) {
    fill(80, 140, 230);
    rect(x, y, s, s);  // square
  } else if (kind.equals("legs")) {
    fill(90, 190, 110);
    triangle(x, y - s / 2, x - s / 2, y + s / 2, x + s / 2, y + s / 2);  // triangle
  }
}
