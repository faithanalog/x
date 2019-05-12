// Saw wave with variable low-pass filtering output over MCP4802
// MCP4802 needs output filtering after it.
#include <SPI.h>


const int ss = 2;

void setup() {
  noInterrupts();
  pinMode(ss, OUTPUT);
  digitalWrite(ss, HIGH); 
  
  SPI.begin();
}

inline void writeDAC(int value) {
  digitalWrite(ss, LOW);
  SPI.beginTransaction(SPISettings(20000000, MSBFIRST, SPI_MODE0));
  SPI.transfer16((0x1 << 12) | ((value & 0xFF) << 4));
  SPI.endTransaction();
  digitalWrite(ss, HIGH);
}

inline word fmul(word a, word b) {
  unsigned long result = (unsigned long)a * (unsigned long)b;
  return (word)((result >> 8) & 0xFFFF);
}




void loop() {
//  return;
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
    delayMicroseconds(16);
  }
  
}
