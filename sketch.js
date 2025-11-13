// Visualización Creativa del Tiempo
// Inspirada en "The Digital Architecture of Time Management" de Judy Wajcman
// Concepto: El tiempo como fluido orgánico, fragmentado y múltiple

let particles = [];
let numParticles = 200;

function setup() {
    createCanvas(windowWidth, windowHeight);
    colorMode(HSB, 360, 100, 100, 100);

    // Inicializar partículas
    for (let i = 0; i < numParticles; i++) {
        particles.push(new TimeParticle(i));
    }
}

function draw() {
    // Obtener tiempo actual
    let s = second();
    let m = minute();
    let h = hour();
    let d = day();
    let mo = month();
    let y = year();

    // Normalizar valores (0-1)
    let normS = s / 60;
    let normM = m / 60;
    let normH = h / 24;
    let normD = d / 31;
    let normMo = mo / 12;

    // Fondo con gradiente según hora del día
    drawTimeBackground(normH, normM);

    // Centro del canvas
    let cx = width / 2;
    let cy = height / 2;

    // 1. CAPA: Ondas del Año (más externa, muy lenta)
    drawTimeRing(cx, cy, 400, normMo + normD/31, 6, normMo * 360, 80, 50);

    // 2. CAPA: Espiral del Mes (intermedia)
    drawTimeSpiral(cx, cy, 320, normD, 12, normH * 360, 70, 60);

    // 3. CAPA: Pulsos del Día (interna)
    drawTimePulse(cx, cy, 240, normH, normM, normS);

    // 4. CAPA: Órbitas de Horas y Minutos
    drawTimeOrbits(cx, cy, normH, normM, normS);

    // 5. CAPA: Partículas de Segundos
    for (let particle of particles) {
        particle.update(normS, normM, normH);
        particle.display();
    }

    // 6. CAPA CENTRAL: Núcleo temporal
    drawTimeCore(cx, cy, normS, normM, normH);
}

// Fondo dinámico que cambia con la hora del día
function drawTimeBackground(normH, normM) {
    // Ciclo de 24 horas = gradiente completo
    let hue1 = (normH * 360 + normM * 6) % 360;
    let hue2 = (hue1 + 180) % 360;

    for (let y = 0; y < height; y++) {
        let inter = map(y, 0, height, 0, 1);
        let c = lerpColor(
            color(hue1, 60, 20),
            color(hue2, 40, 10),
            inter
        );
        stroke(c);
        line(0, y, width, y);
    }
}

// Anillos concéntricos que representan ciclos largos (meses/año)
function drawTimeRing(x, y, radius, rotation, numSegments, hue, sat, bright) {
    push();
    translate(x, y);
    rotate(rotation * TWO_PI);

    noFill();
    strokeWeight(3);

    for (let i = 0; i < numSegments; i++) {
        let angle = (TWO_PI / numSegments) * i;
        let nextAngle = (TWO_PI / numSegments) * (i + 1);

        let opacity = map(sin(rotation * TWO_PI * 4 + i), -1, 1, 30, 70);
        stroke(hue, sat, bright, opacity);

        arc(0, 0, radius, radius, angle, nextAngle);

        // Líneas radiales
        let x1 = cos(angle) * (radius - 30);
        let y1 = sin(angle) * (radius - 30);
        let x2 = cos(angle) * (radius + 30);
        let y2 = sin(angle) * (radius + 30);

        strokeWeight(1);
        line(x1, y1, x2, y2);
        strokeWeight(3);
    }
    pop();
}

// Espiral que representa días del mes
function drawTimeSpiral(x, y, maxRadius, rotation, numArms, hue, sat, bright) {
    push();
    translate(x, y);

    let numPoints = 100;
    noFill();
    strokeWeight(2);

    for (let arm = 0; arm < numArms; arm++) {
        beginShape();
        for (let i = 0; i < numPoints; i++) {
            let progress = i / numPoints;
            let angle = progress * TWO_PI * 2 + rotation * TWO_PI + (arm * TWO_PI / numArms);
            let r = progress * maxRadius;

            let px = cos(angle) * r;
            let py = sin(angle) * r;

            let opacity = map(progress, 0, 1, 70, 20);
            stroke(hue, sat, bright, opacity);
            vertex(px, py);
        }
        endShape();
    }
    pop();
}

// Pulso central que late con segundos
function drawTimePulse(x, y, baseRadius, normH, normM, normS) {
    push();
    translate(x, y);

    // Pulso basado en segundos
    let pulse = sin(normS * TWO_PI) * 20;

    // Múltiples anillos pulsantes
    for (let i = 0; i < 5; i++) {
        let r = baseRadius - i * 30 + pulse * (i + 1);
        let opacity = map(i, 0, 5, 60, 20);
        let hue = (normH * 360 + i * 30) % 360;

        noFill();
        stroke(hue, 70, 80, opacity);
        strokeWeight(2 + i * 0.5);
        circle(0, 0, r);
    }
    pop();
}

// Órbitas de elementos que representan horas y minutos
function drawTimeOrbits(x, y, normH, normM, normS) {
    push();
    translate(x, y);

    // Órbita de Horas (12 elementos)
    for (let i = 0; i < 12; i++) {
        let angle = (i / 12) * TWO_PI - HALF_PI + normH * TWO_PI;
        let radius = 180;
        let px = cos(angle) * radius;
        let py = sin(angle) * radius;

        let size = 8 + sin(normS * TWO_PI + i) * 4;
        let hue = (normH * 360) % 360;

        fill(hue, 80, 90, 70);
        noStroke();
        circle(px, py, size);
    }

    // Órbita de Minutos (60 elementos, cada 5 minutos)
    for (let i = 0; i < 12; i++) {
        let angle = (i / 12) * TWO_PI - HALF_PI + normM * TWO_PI;
        let radius = 140;
        let px = cos(angle) * radius;
        let py = sin(angle) * radius;

        let size = 5 + sin(normS * TWO_PI * 2 + i) * 2;
        let hue = ((normH * 360) + 60) % 360;

        fill(hue, 70, 85, 60);
        noStroke();
        circle(px, py, size);
    }
    pop();
}

// Núcleo central que cambia con el tiempo
function drawTimeCore(x, y, normS, normM, normH) {
    push();
    translate(x, y);

    let coreSize = 60 + sin(normS * TWO_PI) * 15;
    let hue = (normH * 360 + normM * 6) % 360;

    // Múltiples capas del núcleo
    for (let i = 0; i < 3; i++) {
        let size = coreSize - i * 15;
        let rotation = normM * TWO_PI + i * 0.5;

        push();
        rotate(rotation);

        fill(hue, 90 - i * 20, 95 - i * 10, 80 - i * 20);
        noStroke();

        // Crear forma orgánica
        beginShape();
        for (let a = 0; a < TWO_PI; a += 0.2) {
            let r = size/2 + sin(a * 3 + normS * TWO_PI) * 8;
            let px = cos(a) * r;
            let py = sin(a) * r;
            vertex(px, py);
        }
        endShape(CLOSE);
        pop();
    }
    pop();
}

// Clase para partículas que fluyen con el tiempo
class TimeParticle {
    constructor(index) {
        this.index = index;
        this.baseAngle = (index / numParticles) * TWO_PI;
        this.baseRadius = random(100, 350);
        this.size = random(2, 6);
        this.speed = random(0.5, 2);
    }

    update(normS, normM, normH) {
        // Posición basada en tiempo
        this.angle = this.baseAngle + normS * TWO_PI * this.speed;

        // Radio que oscila con minutos
        let radiusOffset = sin(normM * TWO_PI + this.index * 0.1) * 50;
        this.radius = this.baseRadius + radiusOffset;

        // Calcular posición
        this.x = width/2 + cos(this.angle) * this.radius;
        this.y = height/2 + sin(this.angle) * this.radius;

        // Color basado en hora
        this.hue = (normH * 360 + this.index * 3) % 360;
        this.opacity = map(sin(normS * TWO_PI + this.index * 0.1), -1, 1, 20, 80);
    }

    display() {
        push();
        fill(this.hue, 80, 90, this.opacity);
        noStroke();
        circle(this.x, this.y, this.size);

        // Estela de la partícula
        stroke(this.hue, 70, 80, this.opacity * 0.5);
        strokeWeight(1);
        let prevX = width/2 + cos(this.angle - 0.1) * this.radius;
        let prevY = height/2 + sin(this.angle - 0.1) * this.radius;
        line(prevX, prevY, this.x, this.y);
        pop();
    }
}

function windowResized() {
    resizeCanvas(windowWidth, windowHeight);
}
