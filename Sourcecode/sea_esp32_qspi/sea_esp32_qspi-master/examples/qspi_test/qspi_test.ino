#include "sea_esp32_qspi.h"
void setup()
{
  uint8_t data1[2]={42,33};
  uint8_t data2[6] = {0, 0,0,0,0,0};
  
  Serial.begin(115200);
  
  SeaTrans.begin();
  SeaTrans.write(0, data1, 2);
  SeaTrans.read(0, data2, 6);
  
  Serial.printf("%d %d %d %d %d %d \r\n",data2[0],data2[1],data2[2],data2[3],data2[4],data2[5]);
}

void loop()
{
}
