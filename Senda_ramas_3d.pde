// Importamos la librería para la cámara 3D
import peasy.*;

PeasyCam cam;
ArrayList<Branch> network;

// Paleta de colores futurista/distópica
color[] palette = {
  color(255, 80, 200), // Magenta Neón
  color(80, 255, 220), // Verde Ácido / Cian
  color(80, 150, 255)  // Azul Eléctrico
};

// --- VARIABLES PARA EL CRECIMIENTO TEMPORAL ---
float globalTime = 0; // Tiempo global de la simulación
float growthSpeed = 0.02; // Velocidad de crecimiento (más alto = más rápido)
int maxBranches = 2000; // Límite máximo de ramas

void setup() {
  fullScreen(P3D, 2);
  
  cam = new PeasyCam(this, 600);
  smooth(8);
  
  initGrowth();
}

void draw() {
  background(5, 0, 10);

  // --- ILUMINACIÓN DRAMÁTICA ---
  pointLight(255, 100, 100, -width/2, -height/2, 500);
  pointLight(100, 100, 255, width/2, 0, 500);
  ambientLight(20, 20, 20);

  // --- ACTUALIZAMOS EL TIEMPO GLOBAL ---
  globalTime += growthSpeed;

  // --- LÓGICA DE CRECIMIENTO CONTROLADO POR TIEMPO ---
  // Solo añadimos nuevas ramas ocasionalmente, no cada frame
  if (frameCount % 5 == 0 && network.size() < maxBranches) { // Cada 5 frames
    addNewBranches();
  }

  // --- DIBUJAMOS SOLO LAS RAMAS QUE DEBEN SER VISIBLES ---
  for (Branch b : network) {
    b.updateAndDisplay(globalTime);
  }
  
  // --- INFORMACIÓN EN PANTALLA ---
  cam.beginHUD();
  fill(255);
  text("Ramas activas: " + network.size(), 10, 20);
  text("Tiempo: " + nf(globalTime, 0, 2), 10, 40);
  text("Presiona 'R' para reiniciar", 10, 60);
  cam.endHUD();
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    initGrowth();
  }
}

void addNewBranches() {
  if (network.size() == 0) return;
  
  // Seleccionamos algunas ramas existentes para que generen hijas
  int numberOfNewBranches = (int)random(1, 4);
  
  for (int i = 0; i < numberOfNewBranches; i++) {
    // Escogemos una rama madre al azar
    Branch parent = network.get(floor(random(network.size())));
    
    // Solo permitimos que crezca si ya está completamente visible
    if (parent.isFullyGrown(globalTime)) {
      Branch newBranch = parent.createChild(globalTime);
      if (newBranch != null) {
        network.add(newBranch);
      }
    }
  }
}

void initGrowth() {
  network = new ArrayList<Branch>();
  globalTime = 0;
  
  // Creamos las semillas iniciales
  for (int i = 0; i < 5; i++) {
    PVector start = new PVector(random(-width/3, width/3), height/2, random(-200, 200));
    PVector dir = new PVector(0, -1, 0);
    dir.setMag(random(20, 50));
    PVector end = PVector.add(start, dir);
    color c = palette[floor(random(palette.length))];
    
    // Cada semilla inicial nace en un momento ligeramente diferente
    float birthTime = i * 0.5;
    network.add(new Branch(start, end, c, birthTime));
  }
}

// =============================================================
// CLASE BRANCH CON CRECIMIENTO TEMPORAL
// =============================================================
class Branch {
  PVector start;
  PVector end;
  PVector dir;
  float len;
  float thickness;
  color branchColor;
  
  // --- NUEVAS VARIABLES PARA EL CRECIMIENTO TEMPORAL ---
  float birthTime;      // Momento en que nació esta rama
  float growthDuration; // Tiempo que tarda en crecer completamente
  boolean hasChildren;  // Para evitar que genere muchas hijas

  Branch(PVector s, PVector e, color c, float birth) {
    start = s.copy();
    end = e.copy();
    branchColor = c;
    birthTime = birth;
    hasChildren = false;
    
    dir = PVector.sub(end, start);
    len = dir.mag();
    
    thickness = map(len, 50, 2, 8, 1);
    if (thickness < 1) thickness = 1;
    
    // El tiempo de crecimiento depende de la longitud
    growthDuration = len * 0.05; // Las ramas más largas tardan más en crecer
  }

  void updateAndDisplay(float currentTime) {
    // Calculamos qué porcentaje de la rama debería ser visible
    float age = currentTime - birthTime;
    
    if (age <= 0) {
      // La rama aún no ha nacido
      return;
    }
    
    float growthProgress = min(age / growthDuration, 1.0);
    
    if (growthProgress <= 0) return;
    
    // Calculamos el punto final actual basado en el progreso
    PVector currentEnd = PVector.lerp(start, end, growthProgress);
    PVector currentDir = PVector.sub(currentEnd, start);
    float currentLen = currentDir.mag();
    
    // Dibujamos la rama con su longitud actual
    drawBranch(start, currentEnd, currentLen, growthProgress);
  }
  
  void drawBranch(PVector drawStart, PVector drawEnd, float drawLen, float alpha) {
    if (drawLen < 0.1) return; // No dibujar ramas muy pequeñas
    
    PVector midpoint = PVector.add(drawStart, drawEnd).mult(0.5);
    PVector drawDir = PVector.sub(drawEnd, drawStart);
    
    pushMatrix();
    translate(midpoint.x, midpoint.y, midpoint.z);

    PVector yAxis = new PVector(0, 1, 0);
    PVector axis = yAxis.cross(drawDir);
    float angle = PVector.angleBetween(yAxis, drawDir);
    
    if (axis.mag() > 0) {
      rotate(angle, axis.x, axis.y, axis.z);
    }

    noStroke();
    
    // El color se desvanece gradualmente al aparecer
    fill(red(branchColor), green(branchColor), blue(branchColor), alpha * 255);
    
    // El grosor también se escala con el progreso
    float currentThickness = thickness * alpha;
    box(currentThickness, drawLen, currentThickness);
    
    popMatrix();
  }
  
  boolean isFullyGrown(float currentTime) {
    float age = currentTime - birthTime;
    return age >= growthDuration;
  }
  
  Branch createChild(float currentTime) {
    if (hasChildren) return null; // Evitar que genere demasiadas hijas
    
    // Solo una probabilidad de crear una hija
    if (random(1) > 0.3) return null;
    
    PVector currentDir = PVector.sub(end, start);
    float originalLength = currentDir.mag();

    // Lógica de perturbación y bias (como antes)
    PVector perturbation = PVector.random3D();
    perturbation.mult(originalLength * 0.8);
    
    PVector bias = new PVector(end.x * 0.05, -height * 0.05, end.z * 0.05);
    bias.normalize();
    bias.mult(originalLength * 0.3);

    currentDir.add(perturbation);
    currentDir.add(bias);
    currentDir.setMag(originalLength * 0.98);

    PVector newStart = end.copy();
    PVector newEnd = PVector.add(newStart, currentDir);
    
    // Color de la hija
    color newColor = this.branchColor;
    if (random(1) > 0.9) {
      newColor = palette[floor(random(palette.length))];
    }
    
    // La hija nace un poco después de que la madre esté completamente crecida
    float childBirthTime = currentTime + random(0.5, 2.0);
    
    hasChildren = true; // Marcamos que ya generó una hija
    
    return new Branch(newStart, newEnd, newColor, childBirthTime);
  }
}
