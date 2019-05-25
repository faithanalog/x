// Saw wave with variable low-pass filtering output over fast PWM
// PWM needs output filtering after it.
// PWM uses pin 6
void setup() {
  noInterrupts();
  pinMode(6, OUTPUT);

  TCCR0A = _BV(WGM00) | _BV(WGM01) | _BV(COM0A1);
  TCCR0B = _BV(CS00);
}

inline void writeDAC(int value) {
  OCR0A = value & 0xFF;
}

inline word fmul(word a, word b) {
  unsigned long result = (unsigned long)a * (unsigned long)b;
  return (word)((result >> 8) & 0xFFFF);
}

void loop() {
  word alphas[4] = {
    8,
    17,
    31,
    56
  };

  word oneMinusAlphas[4] = {
    256 - 8,
    256 - 17,
    256 - 31,
    256 - 56
  };
  
  word s = 0;
  word acc = 220;
  word t = 0;
  word prev = 0;
  word w = 0;
  word a = alphas[0];
  word oma = oneMinusAlphas[0];
  while(1) {
    word v = fmul(a, s) + fmul(oma, prev);
    writeDAC((v >> 8) & 0xFF);
    prev = v;
    s += acc;
    t++;
    if (t == 44100) {
      w = (w + 1) % 4;
      t = 0;
      a = alphas[w];
      oma = oneMinusAlphas[w];
    }
    delayMicroseconds(28);
  }
  
}
