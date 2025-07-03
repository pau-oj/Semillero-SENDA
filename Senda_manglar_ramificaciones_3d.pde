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
float growthSpeed = 0.08; // VELOCIDAD AUMENTADA (de 0.035 a 0.08)
int maxBranches = 15000; // LÍMITE MUCHO MAYOR (de 5000 a 15000)

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
  // Generación CADA FRAME para máxima fluidez
  if (network.size() < maxBranches) { // Cada frame (de cada 2 frames a cada frame)
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
  
  // OPTIMIZACIÓN: Solo revisar las ramas más recientes (candidatas a estar listas)
  int startIndex = max(0, network.size() - 100); // Solo las últimas 100 ramas
  ArrayList<Branch> candidateParents = new ArrayList<Branch>();
  
  // Buscar ramas completamente crecidas solo en las recientes
  for (int i = startIndex; i < network.size(); i++) {
    Branch candidate = network.get(i);
    if (candidate.isFullyGrown(globalTime) && !candidate.hasChildren) {
      candidateParents.add(candidate);
    }
  }
  
  // Si no hay candidatos en las recientes, tomar algunas al azar de todas
  if (candidateParents.size() == 0) {
    for (int i = 0; i < min(10, network.size()); i++) {
      Branch randomBranch = network.get(floor(random(network.size())));
      if (randomBranch.isFullyGrown(globalTime) && !randomBranch.hasChildren) {
        candidateParents.add(randomBranch);
        break; // Solo necesitamos una
      }
    }
  }
  
  // Generar nuevas ramas desde los candidatos
  int numberOfNewBranches = min(candidateParents.size(), (int)random(4, 8));
  
  for (int i = 0; i < numberOfNewBranches; i++) {
    if (candidateParents.size() > 0) {
      Branch parent = candidateParents.get(floor(random(candidateParents.size())));
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
  
  // Más semillas iniciales para más actividad
  for (int i = 0; i < 12; i++) { // Aumentamos de 8 a 12 semillas
    // Posiciones más cerca del centro de la pantalla
    PVector start = new PVector(random(-width/4, width/4), height/3, random(-150, 150));
    PVector dir = new PVector(0, -1, 0);
    dir.setMag(random(15, 35)); // Ramas iniciales un poco más cortas
    PVector end = PVector.add(start, dir);
    color c = palette[floor(random(palette.length))];
    
    // Intervalos MÁS RÁPIDOS entre nacimientos
    float birthTime = i * 0.15; // Reducimos de 0.3 a 0.15
    network.add(new Branch(start, end, c, birthTime));
  }
}

// =============================================================
// CLASE BRANCH CON CRECIMIENTO TEMPORAL ACELERADO
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
    
    // CRECIMIENTO AÚN MÁS FLUIDO
    growthDuration = len * 0.01; // Reducimos de 0.015 a 0.01 (aún más rápido y fluido)
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
    // Ya no marcamos hasChildren aquí para permitir mejor flujo
    // if (hasChildren) return null; // COMENTAMOS ESTA LÍNEA
    
    // MAYOR probabilidad de ramificación para crecimiento más dinámico
    if (random(1) > 0.4) return null; // Aumentamos de 0.35 a 0.4 para 40% probabilidad
    
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
    
    // NACIMIENTO MÁS FLUIDO de las hijas
    float childBirthTime = currentTime + random(0.05, 0.3);
    
    hasChildren = true; // Marcamos DESPUÉS de crear la hija
    
    return new Branch(newStart, newEnd, newColor, childBirthTime);
  }
}
