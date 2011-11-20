#include <stdlib.h>
#include <SoftwareTone.h>
#include <TimerOne.h>


char dataIn[128];
int dataInIndex;
int toneVals[12];
unsigned long lastUpdate;

void setup()
{
Serial.begin(57600);
SoftwareTone.init();
lastUpdate = millis();
}


void parseLine(char *str)
{
for (int i = 0; i < 12; i++) {
  toneVals[i] = strtol(str, &str, 10);
  if (toneVals[i] > 1000) { toneVals[i] = 1000; }
  if (toneVals[i] < 1) { toneVals[i] = 1; }
}

for (int i = 0; i < 12; i++) {
  SoftwareTone.setFreq(i + 2, toneVals[i]);
}

lastUpdate = millis();
}


void loop()
{
int c;

if (Serial.available()) {
  c = Serial.read();
  dataIn[dataInIndex++] = c;

  if (c == '\n') {
    dataIn[dataInIndex] = '\0';
    parseLine(dataIn);
    dataInIndex = 0;
  }

  if (dataInIndex >= (sizeof(dataIn) - 1)) {
    dataInIndex = 0;
  }
}

if (millis() - lastUpdate > 1000) {
  for (int i = 0; i < 12; i++) {
    SoftwareTone.setFreq(i + 2, 0);   
  }
}
}
